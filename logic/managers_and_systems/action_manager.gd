# action_manager.gd
class_name ActionManager
extends Node

## The rules engine. Every change to the game state is an Action that goes through
## request_action(). Actions resolve one at a time, in the order they were requested:
##
##   validate -> action_resolving (listeners may cancel) -> execute -> action_resolved
##
## Anything requested while an action is resolving (by a listener, the AI, the game itself)
## is queued behind it instead of running in the middle of it. Listeners therefore always see
## a finished state, and chains of follow-up actions never nest.
##
## action_resolved is the game's event stream: triggered and delayed abilities subscribe to it.

## About to execute. A listener may call action.cancel(reason) to stop it.
signal action_resolving(action: Action)
## Finished executing. The game state already reflects it.
signal action_resolved(action: Action)
signal action_rejected(action: Action, reason: String)

## Stops a runaway chain (e.g. two triggers re-queuing each other forever).
const MAX_ACTIONS_PER_CHAIN: int = 1000

const SYSTEM_TYPES: Array[Action.Type] = [
	Action.Type.FINISH_SETUP,
	Action.Type.COLLECT_UPKEEP,
	Action.Type.RESOLVE_COMBAT,
]

var _lander_manager: LanderManager
var _turn_manager: TurnManager
var _combat_manager: CombatManager
var _match_settings: MatchSettings

var _queue: Array[Action] = []
var _is_resolving: bool = false


#region Public API
func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_manager = lander_manager


func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager


func bind_combat_manager(combat_manager: CombatManager) -> void:
	_combat_manager = combat_manager


func bind_match_settings(match_settings: MatchSettings) -> void:
	_match_settings = match_settings


## Queues `action`. If nothing is resolving, resolves it (and everything it causes) right away.
func request_action(action: Action) -> void:
	_queue.append(action)
	if _is_resolving:
		return

	_is_resolving = true
	var resolved_count := 0
	while not _queue.is_empty():
		resolved_count += 1
		if resolved_count > MAX_ACTIONS_PER_CHAIN:
			push_error("ActionManager | More than %d actions in one chain; dropping %d queued actions"
				% [MAX_ACTIONS_PER_CHAIN, _queue.size()])
			_queue.clear()
			break
		_resolve(_queue.pop_front())
	_is_resolving = false


func is_resolving() -> bool:
	return _is_resolving
#endregion


#region Resolution
func _resolve(action: Action) -> void:
	var reason := _validate(action)
	if reason != "":
		_reject(action, reason)
		return

	action_resolving.emit(action)
	if action.is_cancelled():
		_reject(action, action.get_cancel_reason())
		return

	_execute(action)
	action_resolved.emit(action)


## Asks for a follow-up action. It resolves after the current one (and anything queued before it).
func _queue_system_action(type: Action.Type, actor: Actor = null) -> void:
	_queue.append(Action.create_system(type, actor))


## After the phase changes: pay upkeep, and move straight through admin phases.
func _queue_phase_automation() -> void:
	var phase := _turn_manager.get_game_phase()
	if phase == TurnManager.Phase.UPKEEP:
		_queue_system_action(Action.Type.COLLECT_UPKEEP, _turn_manager.get_active_actor())
	if phase in _turn_manager.get_admin_phases():
		_queue_system_action(Action.Type.PROGRESS_TURN)
#endregion


#region Validation
## Returns why `action` is not allowed right now, or "" if it is.
func _validate(action: Action) -> String:
	var type := action.get_type()
	if type in SYSTEM_TYPES and not action.is_system():
		return "Only the game can request this action"
	if not action.is_system() and action.get_actor() == null:
		return "Action has no actor"

	match type:
		Action.Type.PLACE_BIOME:
			return _validate_place_biome(action)
		Action.Type.PLACE_BUILDING:
			return _validate_place_building(action)
		Action.Type.FINISH_SETUP:
			return _validate_finish_setup(action)
		Action.Type.PLACE_LANDER:
			return _validate_place_lander(action)
		Action.Type.PURCHASE:
			return _validate_purchase(action)
		Action.Type.MOVE_UNITS:
			return _validate_move_units(action)
		Action.Type.ATTACK:
			return _validate_attack(action)
		Action.Type.PROGRESS_TURN:
			return _validate_progress_turn(action)
		Action.Type.SELECT_COMBAT_UNIT:
			return _validate_select_combat_unit(action)
		Action.Type.DESELECT_COMBAT_UNIT:
			return _validate_deselect_combat_unit(action)
		Action.Type.DECLARE_COMBAT_READY:
			return _validate_declare_combat_ready(action)
		Action.Type.WITHDRAW_COMBAT_READY:
			return _require_combat_participant(action)
		Action.Type.RETREAT_COMBAT:
			return _validate_retreat_combat(action)
		Action.Type.COLLECT_UPKEEP:
			return "" if action.get_actor() != null else "Upkeep needs an actor"
		Action.Type.RESOLVE_COMBAT:
			return _validate_resolve_combat()
	return "Unknown action type"


func _validate_place_biome(action: Action) -> String:
	if _turn_manager.get_game_state() != TurnManager.GameState.SETUP:
		return "Biomes can only be placed during setup"
	if action.get_biome_data() == null:
		return "No biome chosen"
	if not _lander_manager.is_valid_lander_placement(action.get_position()):
		return "Invalid lander placement"
	return ""


## PLACE_BUILDING is only the free command tower at the end of setup.
## Every other building is bought with PURCHASE.
func _validate_place_building(action: Action) -> String:
	if _turn_manager.get_game_state() != TurnManager.GameState.SETUP:
		return "Buildings are bought with PURCHASE outside of setup"
	var command_tower := action.get_actor().get_species().get_command_tower()
	if action.get_building_data() != command_tower:
		return "Only the command tower can be placed for free"
	var lander := action.get_target_lander()
	if lander == null:
		return "Missing target lander"
	if lander.has_building():
		return "Lander already has a building"
	if _has_command_tower(action.get_actor()):
		return "Actor already has a command tower"
	return ""


func _validate_finish_setup(_action: Action) -> String:
	if _turn_manager.get_game_state() != TurnManager.GameState.SETUP:
		return "Setup is already finished"
	return ""


func _validate_place_lander(action: Action) -> String:
	var reason := _require_turn(action, TurnManager.Phase.DUSTCLOUD_COLLAPSE)
	if reason != "":
		return reason
	if not _lander_manager.is_valid_lander_placement(action.get_position()):
		return "Invalid lander placement"
	return ""


func _validate_purchase(action: Action) -> String:
	var reason := _require_turn(action, TurnManager.Phase.BUYING)
	if reason != "":
		return reason

	var actor := action.get_actor()
	var lander := action.get_target_lander()
	var purchasable := action.get_purchasable()
	if lander == null:
		return "Missing target lander"
	if purchasable == null:
		return "Nothing chosen to buy"
	if lander.get_owner_actor() != actor:
		return "Actor does not own the target lander"
	if purchasable not in lander.get_purchasables(actor):
		return "'%s' can't be bought on this lander" % purchasable.get("display_name")
	if not actor.get_wallet().can_afford(_get_cost(purchasable)):
		return "Actor can not afford '%s'" % purchasable.get("display_name")

	if purchasable is BuildingData:
		if lander.has_building():
			return "Lander already has a building (upgrades aren't implemented yet)"
		if (purchasable as BuildingData).is_unique_building() and _owns_building(actor, purchasable):
			return "'%s' is unique and the actor already has one" % purchasable.get("display_name")
	if purchasable is UnitData and lander.is_full():
		return "Lander is full"
	return ""


func _validate_move_units(action: Action) -> String:
	var reason := _require_turn(action, TurnManager.Phase.COMBAT)
	if reason != "":
		return reason
	if _combat_manager.is_in_progress():
		return "Finish the current combat first"
	reason = _require_two_connected_landers(action)
	if reason != "":
		return reason

	var actor := action.get_actor()
	var source := action.get_source_lander()
	var target := action.get_target_lander()
	var units := action.get_units()
	if units.is_empty():
		return "No units chosen"
	for unit in units:
		if unit not in source.get_units():
			return "A chosen unit is not on the source lander"
		if unit.get_owner_actor() != actor:
			return "A chosen unit belongs to someone else"
	if target.has_units() and target.get_units()[0].get_owner_actor() != actor:
		return "Target lander has enemy units: attack it instead"
	if _has_enemy_building(target, actor) and action.get_building_fate() == Action.BuildingFate.NONE:
		return "The enemy building is undefended: choose to capture or raze it"
	if target.get_units().size() + units.size() > target.get_unit_capacity():
		return "Target lander doesn't have room for those units"
	return ""


func _validate_attack(action: Action) -> String:
	var reason := _require_turn(action, TurnManager.Phase.COMBAT)
	if reason != "":
		return reason
	if _combat_manager.is_in_progress():
		return "A combat is already in progress"
	reason = _require_two_connected_landers(action)
	if reason != "":
		return reason

	var source_units := action.get_source_lander().get_units()
	var target_units := action.get_target_lander().get_units()
	if source_units.is_empty():
		return "Source lander has no units"
	if target_units.is_empty():
		return "Target lander has no defenders: move in instead (and capture or raze any building)"
	if source_units[0].get_owner_actor() != action.get_actor():
		return "Attacking units don't belong to the attacking actor"
	if target_units[0].get_owner_actor() == action.get_actor():
		return "Source and target landers are allies"
	return ""


func _validate_progress_turn(action: Action) -> String:
	if _turn_manager.get_game_state() != TurnManager.GameState.MAIN_LOOP:
		return "The turn can only be progressed in the main loop"
	if action.is_system():
		return ""  # The game moving through admin phases or after a lander is placed.
	if _turn_manager.get_active_actor() != action.get_actor():
		return "It is not this actor's turn"
	var phase := _turn_manager.get_game_phase()
	if phase in _turn_manager.get_admin_phases():
		return "Admin phases can't be progressed by an actor"
	if phase in _turn_manager.get_non_skippable_phases():
		return "%s can't be skipped: complete it first (place a lander)" % TurnManager.get_phase_name(phase)
	if _combat_manager.is_in_progress():
		return "Finish the current combat first"
	return ""


func _validate_select_combat_unit(action: Action) -> String:
	var reason := _require_combat_participant(action)
	if reason != "":
		return reason
	if action.get_units().size() != 1:
		return "Select exactly one unit"

	var contest := _combat_manager.get_contest()
	var side := contest.get_side_of(action.get_actor())
	var unit := action.get_units()[0]
	if unit.get_owner_actor() != action.get_actor():
		return "That unit belongs to someone else"
	if unit not in contest.get_lander(side).get_units():
		return "That unit isn't on this side's lander"
	if unit in contest.get_units(side):
		return "That unit is already selected"
	if contest.get_units(side).size() >= _combat_manager.get_max_units(side):
		return "%s already has the maximum number of units selected" % Contest.Side.find_key(side)
	return ""


func _validate_deselect_combat_unit(action: Action) -> String:
	var reason := _require_combat_participant(action)
	if reason != "":
		return reason
	if action.get_units().size() != 1:
		return "Deselect exactly one unit"
	var contest := _combat_manager.get_contest()
	if action.get_units()[0] not in contest.get_units(contest.get_side_of(action.get_actor())):
		return "That unit isn't selected"
	return ""


## A side that still has units must pick at least one, or the battle could never end.
func _validate_declare_combat_ready(action: Action) -> String:
	var reason := _require_combat_participant(action)
	if reason != "":
		return reason
	var contest := _combat_manager.get_contest()
	var side := contest.get_side_of(action.get_actor())
	if contest.get_units(side).is_empty() and not contest.get_available_units(side).is_empty():
		return "Select at least one unit to fight with first"
	return ""


func _validate_retreat_combat(action: Action) -> String:
	var reason := _require_combat_participant(action)
	if reason != "":
		return reason
	if _combat_manager.get_contest().get_side_of(action.get_actor()) != Contest.Side.ATTACKER:
		return "Only the attacker can retreat"
	return ""


func _validate_resolve_combat() -> String:
	if not _combat_manager.is_selecting():
		return "No combat is waiting to be resolved"
	if not _combat_manager.get_contest().are_both_sides_ready():
		return "Both sides must be ready"
	return ""


## Main loop, this actor's turn, and the given phase.
func _require_turn(action: Action, phase: TurnManager.Phase) -> String:
	if _turn_manager.get_game_state() != TurnManager.GameState.MAIN_LOOP:
		return "Only allowed in the main loop"
	if _turn_manager.get_active_actor() != action.get_actor():
		return "It is not this actor's turn"
	if _turn_manager.get_game_phase() != phase:
		return "Only allowed in the %s phase" % TurnManager.get_phase_name(phase)
	return ""


## Combat is choosing units and the actor is one of the two sides.
func _require_combat_participant(action: Action) -> String:
	if not _combat_manager.is_selecting():
		return "No combat is choosing units right now"
	if not _combat_manager.get_contest().is_involved(action.get_actor()):
		return "Actor is not part of this combat"
	return ""


func _require_two_connected_landers(action: Action) -> String:
	var source := action.get_source_lander()
	var target := action.get_target_lander()
	if source == null or target == null:
		return "Missing source or target lander"
	if source == target:
		return "Source and target are the same lander"
	if target not in _lander_manager.get_connected_landers(source):
		return "Target lander is not connected to the source lander"
	return ""
#endregion


#region Execution
## Applies an action that has already passed _validate().
func _execute(action: Action) -> void:
	match action.get_type():
		Action.Type.PLACE_BIOME:
			_lander_manager.spawn_biome_lander(action)

		Action.Type.PLACE_BUILDING:
			action.get_target_lander().build(action)
			# The command tower is the last setup step.
			_queue_system_action(Action.Type.FINISH_SETUP)

		Action.Type.FINISH_SETUP:
			_turn_manager.begin_main_loop()
			_queue_phase_automation()

		Action.Type.PLACE_LANDER:
			_lander_manager.spawn_random_lander(action.get_position())
			# Placing the lander is the whole DUSTCLOUD_COLLAPSE phase.
			_queue_system_action(Action.Type.PROGRESS_TURN)

		Action.Type.PURCHASE:
			action.get_actor().get_wallet().subtract(_get_cost(action.get_purchasable()))
			if action.get_purchasable() is BuildingData:
				action.get_target_lander().build(action)
			else:
				action.get_target_lander().buy_unit(action)

		Action.Type.MOVE_UNITS:
			_take_undefended_building(action)
			_lander_manager.move_units(action)

		Action.Type.ATTACK:
			_combat_manager.start_combat(action)

		Action.Type.PROGRESS_TURN:
			_turn_manager.progress_phase()
			_queue_phase_automation()

		Action.Type.SELECT_COMBAT_UNIT:
			_combat_manager.select_unit(action.get_units()[0])

		Action.Type.DESELECT_COMBAT_UNIT:
			_combat_manager.deselect_unit(action.get_units()[0])

		Action.Type.DECLARE_COMBAT_READY:
			_combat_manager.set_actor_ready(action.get_actor(), true)
			if _combat_manager.get_contest().are_both_sides_ready():
				_queue_system_action(Action.Type.RESOLVE_COMBAT)

		Action.Type.WITHDRAW_COMBAT_READY:
			_combat_manager.set_actor_ready(action.get_actor(), false)

		Action.Type.RETREAT_COMBAT:
			_combat_manager.retreat()

		Action.Type.RESOLVE_COMBAT:
			_combat_manager.resolve_combat()

		Action.Type.COLLECT_UPKEEP:
			_collect_upkeep(action.get_actor())
#endregion


#region Private
## Every actor's flat upkeep gold, plus the upkeep of each lander they own.
func _collect_upkeep(actor: Actor) -> void:
	var wallet := actor.get_wallet()
	wallet.set_amount(&"gold", wallet.get_amount(&"gold") + _match_settings.get_upkeep_gold())
	_lander_manager.run_upkeep(actor)


func _get_cost(purchasable: Resource) -> EconData:
	if purchasable is BuildingData:
		return (purchasable as BuildingData).get_cost()
	if purchasable is UnitData:
		return (purchasable as UnitData).get_cost()
	return EconData.new()


func _has_command_tower(actor: Actor) -> bool:
	return _owns_building(actor, actor.get_species().get_command_tower())


func _has_enemy_building(lander: Lander, actor: Actor) -> bool:
	return lander.has_building() and lander.get_building().get_owner_actor() != actor


## Capture or raze the enemy building on a MOVE_UNITS target (validation made sure it's undefended).
func _take_undefended_building(action: Action) -> void:
	var target := action.get_target_lander()
	if not _has_enemy_building(target, action.get_actor()):
		return
	match action.get_building_fate():
		Action.BuildingFate.CAPTURE:
			target.get_building().set_owner_actor(action.get_actor())
			target.refresh_markers()
		Action.BuildingFate.RAZE:
			target.remove_building()


func _owns_building(actor: Actor, building_data: BuildingData) -> bool:
	for lander in _lander_manager.get_landers_owned_by(actor):
		if lander.has_building() and lander.get_building().get_building_data() == building_data:
			return true
	return false


func _reject(action: Action, reason: String) -> void:
	print("ActionManager | Rejected %s | %s" % [Action.Type.find_key(action.get_type()), reason])
	action_rejected.emit(action, reason)
#endregion
