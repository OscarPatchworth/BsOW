# combat_manager.gd
class_name CombatManager
extends Node

#region Declarations
# Signals
signal combat_started(contest: Contest)
signal combat_updated(contest: Contest)
signal combat_outcome(c_out: Array[CombatOutcome])
signal combat_finished()

# Enums
enum CombatLoop { START, SELECT, DAMAGE, CLEANUP, INACTIVE }

# Runtime Refs
var match_settings: Node
var max_attack_units: int
var max_defend_units: int
var max_attack_ablt: int
var max_defend_ablt: int
var current_combat: Contest
var combat_context: CombatContext = CombatContext.new(Contest.new())
var outcome_emitted: bool = false
#endregion

#region Internal Types
class CombatContext:
    var contest: Contest
    var outcomes: Array[CombatOutcome] = []
    var phase := CombatLoop.INACTIVE
    var select_req: CombatSelection
    func _init(c: Contest): contest = c

class CombatSelection:
    enum SelectAction { SELECT, DESELECT }
    enum SelectType { UNIT, ABILITY, READY }
    var who: Actor
    var action: SelectAction
    var type: SelectType
    var selection: Variant
    var completed: bool = false
#endregion

###################################################################################################
#region Setup Flow
func bind_match_settings(ms: Node):
    match_settings = ms
    max_attack_units = match_settings.max_attack_units
    max_defend_units = match_settings.max_defend_units
    max_attack_ablt = match_settings.max_attack_ablt
    max_defend_ablt = match_settings.max_defend_ablt
#endregion

#region Public API
func attack_action(req: Action):
    combat_context.phase = CombatLoop.START
    _start_combat(req)

func actor_selection_req(who: Actor, thing: Variant, select: bool):
    var req = _make_selection_req(who, thing, select)
    if req == null:
        return
    combat_context.select_req = req
    update_combat()

func actor_selected_unit(unit: UnitObject):
    if current_combat.get_invading_actor() == unit.get_owned_by():
        if current_combat.get_invading_units().size() >= max_attack_units:
            print("Combat Manager | Warning | Attacker selecting too many units")
        else:
            current_combat.add_invading_unit(unit)
    elif current_combat.get_defending_actor() == unit.get_owned_by():
        if current_combat.get_defending_units().size() >= max_defend_units:
            print("Combat Manager | Warning | Defender selecting too many units")
        else:
            current_combat.add_defending_unit(unit)

func actor_deselected_unit(unit: UnitObject):
    if current_combat.get_invading_actor() != unit.get_owned_by():
        print("Combat Manager | Err | Actor attempted to deselect un-owned unit")
    else:
        current_combat.rmv_invading_unit(unit)

func player_ready(ready_player: Actor):
    if current_combat.get_invading_actor() == ready_player:
        current_combat.set_invading_ready(true)
    elif current_combat.get_defending_actor() == ready_player:
        current_combat.set_defending_ready(true)
    else:
        print("Combat Manager | ERROR | Actor outside of combat declared Ready")
        return
    if current_combat.get_invading_ready() and current_combat.get_defending_ready():
        set_state_damage()

func player_unready(unready_player: Actor):
    if current_combat.get_invading_actor() == unready_player:
        current_combat.set_invading_ready(false)
    elif current_combat.get_defending_actor() == unready_player:
        current_combat.set_defending_ready(false)
    else:
        print("Combat Manager | ERROR | Actor outside of combat declared not Ready")
        return
#endregion

#region State Machine
func update_combat():
    match combat_context.phase:
        CombatLoop.SELECT:
            run_select_phase()
            if not outcome_emitted:
                combat_updated.emit(current_combat)
        CombatLoop.DAMAGE:
            run_damage_phase()
        CombatLoop.CLEANUP, CombatLoop.START, CombatLoop.INACTIVE:
            return
        _:
            print("Combat Manager | ERR | invalid combat phase")

func run_select_phase():
    if combat_context.select_req == null or combat_context.select_req.completed:
        return
    match combat_context.select_req.type:
        CombatSelection.SelectType.UNIT:
            if not combat_context.select_req.selection is UnitObject:
                print("Combat Manager | Err | Selection and type not compatible")
                return
            match combat_context.select_req.action:
                CombatSelection.SelectAction.SELECT:
                    actor_selected_unit(combat_context.select_req.selection)
                CombatSelection.SelectAction.DESELECT:
                    actor_deselected_unit(combat_context.select_req.selection)
        CombatSelection.SelectType.READY:
            match combat_context.select_req.action:
                CombatSelection.SelectAction.SELECT:
                    player_ready(combat_context.select_req.who)
                CombatSelection.SelectAction.DESELECT:
                    player_unready(combat_context.select_req.who)
        _:
            print("Combat Manager | Err | Selection Type invalid")

func run_damage_phase():
    var invading_dmg = _build_damage_for_units(current_combat.invading_units)
    var defending_dmg = _build_damage_for_units(current_combat.defending_units)
    invading_dmg.sort_custom(func(a, b): return a.get_total() > b.get_total())
    defending_dmg.sort_custom(func(a, b): return a.get_total() > b.get_total())
    _resolve_damage_clashes(invading_dmg, defending_dmg)
    combat_outcome.emit(invading_dmg + defending_dmg)
    outcome_emitted = true
    _apply_outcomes(invading_dmg, defending_dmg)
    set_state_cleanup()

func run_cleanup_phase():
    set_state_inactive()

func set_state_damage():
    if combat_context.phase != CombatLoop.SELECT:
        print("Combat Manager | Err | Attempting to switch to Damage phase outside of Selecting Phase")
        return
    combat_context.phase = CombatLoop.DAMAGE
    update_combat()

func set_state_cleanup():
    if combat_context.phase != CombatLoop.DAMAGE:
        print("Combat Manager | ERR | Attempt to set phase to Cleanup outside of Damage Phase")
        return
    combat_context.phase = CombatLoop.CLEANUP

func set_state_inactive():
    if combat_context.phase != CombatLoop.CLEANUP:
        print("Combat Manager | ERR | Attempt to set phase to inactive outside of Cleanup phase")
        return
    combat_context.phase = CombatLoop.INACTIVE
    outcome_emitted = false
#endregion

#region Helpers
func _start_combat(req: Action):
    current_combat = _action_to_contest(req)
    combat_context = CombatContext.new(current_combat)
    combat_context.phase = CombatLoop.SELECT
    combat_started.emit(current_combat)

func _make_selection_req(who: Actor, thing: Variant, select: bool):
    var req = CombatSelection.new()
    req.who = who
    req.selection = thing
    req.action = CombatSelection.SelectAction.SELECT if select else CombatSelection.SelectAction.DESELECT
    match thing:
        _ when thing is UnitObject:
            req.type = CombatSelection.SelectType.UNIT
        _ when thing is bool:
            req.type = CombatSelection.SelectType.READY
        _:
            print("Combat Manager | Err | Selection request not of any compatible type")
            return null
    return req

func _build_damage_for_units(units: Array) -> Array[CombatOutcome]:
    var outcomes: Array[CombatOutcome] = []
    for unit in units:
        var outcome = CombatOutcome.new()
        outcome.set_unit(unit)
        var dmg = unit.get_unit_data().get_dmg()
        for _i in dmg.get_dice_amount():
            outcome.add_roll((randi() % dmg.get_damage_dice()) + 1)
        outcome.add_mod(dmg.get_damage_mod())
        outcome.set_total(outcome.calc_total())
        outcomes.append(outcome)
    return outcomes

func _resolve_damage_clashes(invading_dmg: Array[CombatOutcome], defending_dmg: Array[CombatOutcome]) -> void:
    for i in range(min(invading_dmg.size(), defending_dmg.size())):
        if invading_dmg[i].get_total() > defending_dmg[i].get_total():
            invading_dmg[i].set_reason(CombatOutcome.Reasons.COMBAT_WON)
            defending_dmg[i].set_reason(CombatOutcome.Reasons.COMBAT_LOST)
        else:
            invading_dmg[i].set_reason(CombatOutcome.Reasons.COMBAT_LOST)
            defending_dmg[i].set_reason(CombatOutcome.Reasons.COMBAT_WON)

func _apply_outcomes(invading_dmg: Array[CombatOutcome], defending_dmg: Array[CombatOutcome]) -> void:
    for attacker in invading_dmg:
        if attacker.get_outcome() == CombatOutcome.Outcome.DEAD:
            current_combat.get_invading_lander().rmv_units([attacker.get_unit()])
    for defender in defending_dmg:
        if defender.get_outcome() == CombatOutcome.Outcome.DEAD:
            current_combat.get_contested_lander().rmv_units([defender.get_unit()])

func _action_to_contest(req: Action) -> Contest:
    var contest = Contest.new()
    contest.set_contested_lander(req.target_lander)
    contest.set_invading_lander(req.selected_lander)
    return contest
#endregion

#region State Queries
func get_max_attack_units() -> int: return max_attack_units
func set_max_attack_units(max_u: int): max_attack_units = max_u
func get_max_defend_units() -> int: return max_defend_units
func set_max_defend_units(max_u: int): max_defend_units = max_u
func get_max_attack_ablt() -> int: return max_attack_ablt
func set_max_attack_ablt(max_a: int): max_attack_ablt = max_a
func get_max_defend_ablt() -> int: return max_defend_ablt
func set_max_defend_ablt(max_a: int): max_defend_ablt = max_a
#endregion