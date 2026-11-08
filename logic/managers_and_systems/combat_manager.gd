# combat_manager.gd
class_name CombatManager
extends Node

## Runs a contest: both sides pick units and ready up, then damage is rolled and resolved.
## Flow: start_combat() -> SELECT (selections/ready) -> resolve_combat(): DAMAGE -> CLEANUP.
## Every step is requested through the ActionManager, which checks the rules first;
## this class only applies the change and announces it.

signal combat_started(contest: Contest)
signal combat_updated(contest: Contest)
signal combat_resolved(outcomes: Array[CombatOutcome])

enum CombatPhase {
	INACTIVE,
	START,
	SELECT,
	DAMAGE,
	CLEANUP,
}

var _match_settings: MatchSettings
var _contest: Contest
var _phase: CombatPhase = CombatPhase.INACTIVE

var _max_units := {Contest.Side.ATTACKER: 0, Contest.Side.DEFENDER: 0}
var _max_abilities := {Contest.Side.ATTACKER: 0, Contest.Side.DEFENDER: 0}


#region Public API
func bind_match_settings(match_settings: MatchSettings) -> void:
	_match_settings = match_settings
	set_max_units(Contest.Side.ATTACKER, match_settings.get_max_attacker_units())
	set_max_units(Contest.Side.DEFENDER, match_settings.get_max_defender_units())
	set_max_abilities(Contest.Side.ATTACKER, match_settings.get_max_attacker_abilities())
	set_max_abilities(Contest.Side.DEFENDER, match_settings.get_max_defender_abilities())


func start_combat(action: Action) -> void:
	_phase = CombatPhase.START
	set_contest(Contest.new(action.get_source_lander(), action.get_target_lander()))
	_phase = CombatPhase.SELECT
	combat_started.emit(get_contest())


func select_unit(unit: UnitInstance) -> void:
	var side := get_contest().get_side_of(unit.get_owner_actor())
	if side == -1:
		push_warning("CombatManager | Unit owner is not part of this contest")
		return
	get_contest().add_unit(side, unit)
	combat_updated.emit(get_contest())


func deselect_unit(unit: UnitInstance) -> void:
	var side := get_contest().get_side_of(unit.get_owner_actor())
	if side == -1:
		push_warning("CombatManager | Unit owner is not part of this contest")
		return
	get_contest().remove_unit(side, unit)
	combat_updated.emit(get_contest())


func set_actor_ready(actor: Actor, is_ready: bool) -> void:
	var side := get_contest().get_side_of(actor)
	if side == -1:
		push_warning("CombatManager | Actor outside of combat changed its ready state")
		return
	get_contest().set_ready(side, is_ready)
	combat_updated.emit(get_contest())


## Rolls damage for both sides, decides each pairing, and removes the dead.
func resolve_combat() -> void:
	if _phase != CombatPhase.SELECT:
		push_warning("CombatManager | resolve_combat() called outside of the select phase")
		return
	_phase = CombatPhase.DAMAGE

	var contest := get_contest()
	var attacker_outcomes := _roll_side(contest.get_units(Contest.Side.ATTACKER))
	var defender_outcomes := _roll_side(contest.get_units(Contest.Side.DEFENDER))

	# Highest roll faces highest roll. Ties go to the defender.
	for i in mini(attacker_outcomes.size(), defender_outcomes.size()):
		if attacker_outcomes[i].get_total() > defender_outcomes[i].get_total():
			attacker_outcomes[i].set_reason(CombatOutcome.Reason.COMBAT_WON)
			defender_outcomes[i].set_reason(CombatOutcome.Reason.COMBAT_LOST)
		else:
			attacker_outcomes[i].set_reason(CombatOutcome.Reason.COMBAT_LOST)
			defender_outcomes[i].set_reason(CombatOutcome.Reason.COMBAT_WON)

	for outcome in attacker_outcomes:
		print(outcome.to_debug_dictionary())
	print("#####")
	for outcome in defender_outcomes:
		print(outcome.to_debug_dictionary())

	_remove_dead(attacker_outcomes, contest.get_lander(Contest.Side.ATTACKER))
	_remove_dead(defender_outcomes, contest.get_lander(Contest.Side.DEFENDER))
	_phase = CombatPhase.CLEANUP

	var all_outcomes: Array[CombatOutcome] = []
	all_outcomes.append_array(attacker_outcomes)
	all_outcomes.append_array(defender_outcomes)
	combat_resolved.emit(all_outcomes)


## Both sides are choosing units and readying up.
func is_selecting() -> bool:
	return _phase == CombatPhase.SELECT


## A contest has started and not been resolved yet.
func is_in_progress() -> bool:
	return _phase in [CombatPhase.START, CombatPhase.SELECT, CombatPhase.DAMAGE]
#endregion


#region Accessors
func get_contest() -> Contest:
	return AbilitySystem.resolve_get(self, &"contest", _contest)


func set_contest(value: Contest) -> void:
	_contest = AbilitySystem.resolve_set(self, &"contest", _contest, value)


func get_phase() -> CombatPhase:
	return _phase


func get_max_units(side: int) -> int:
	return AbilitySystem.resolve_get(self, _side_key(side, "units"), _max_units[side])


func set_max_units(side: int, value: int) -> void:
	_max_units[side] = AbilitySystem.resolve_set(self, _side_key(side, "units"), _max_units[side], value)


func get_max_abilities(side: int) -> int:
	return AbilitySystem.resolve_get(self, _side_key(side, "abilities"), _max_abilities[side])


func set_max_abilities(side: int, value: int) -> void:
	_max_abilities[side] = AbilitySystem.resolve_set(self, _side_key(side, "abilities"), _max_abilities[side], value)
#endregion


#region Private
## Rolls damage for each unit and returns the outcomes sorted highest total first.
func _roll_side(units: Array[UnitInstance]) -> Array[CombatOutcome]:
	var outcomes: Array[CombatOutcome] = []
	for unit in units:
		var outcome := CombatOutcome.new(unit)
		outcome.roll_damage()
		outcomes.append(outcome)
	outcomes.sort_custom(func(a: CombatOutcome, b: CombatOutcome) -> bool: return a.get_total() > b.get_total())
	return outcomes


func _remove_dead(outcomes: Array[CombatOutcome], lander: Lander) -> void:
	var dead: Array[UnitInstance] = []
	for outcome in outcomes:
		if outcome.get_outcome() == CombatOutcome.Outcome.DEAD:
			dead.append(outcome.get_unit())
	if not dead.is_empty():
		lander.remove_units(dead)


## e.g. (ATTACKER, "units") -> &"max_attacker_units"
func _side_key(side: int, field: String) -> StringName:
	return StringName("max_" + ("attacker_" if side == Contest.Side.ATTACKER else "defender_") + field)
#endregion
