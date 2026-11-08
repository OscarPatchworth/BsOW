# combat_manager.gd
class_name CombatManager
extends Node

## Runs a contest: both sides pick units and ready up, then damage is rolled and resolved.
## Flow: start_combat() -> SELECT (selections/ready) -> DAMAGE -> CLEANUP.

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

## What a combat selection request is about.
enum SelectionType {
	UNIT,
	ABILITY,
	READY,
}

var _match_settings: MatchSettings
var _contest: Contest
var _phase: CombatPhase = CombatPhase.INACTIVE
var _outcome_emitted: bool = false

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
	_outcome_emitted = false
	set_contest(Contest.new(action.get_source_lander(), action.get_target_lander()))
	_phase = CombatPhase.SELECT
	combat_started.emit(get_contest())


## Entry point for the Player's combat UI.
## `thing` is a UnitInstance (select/deselect it) or a bool (ready / not ready).
func request_selection(actor: Actor, thing: Variant, is_selected: bool) -> void:
	if _phase != CombatPhase.SELECT:
		print("CombatManager | Selection request outside of the select phase")
		return

	if thing is UnitInstance:
		if is_selected:
			select_unit(thing)
		else:
			deselect_unit(thing)
	elif thing is bool:
		if is_selected:
			set_actor_ready(actor)
		else:
			set_actor_not_ready(actor)
	else:
		print("CombatManager | Selection request is not a unit or ready flag")
		return

	if not _outcome_emitted:
		combat_updated.emit(get_contest())


func select_unit(unit: UnitInstance) -> void:
	var side := get_contest().get_side_of(unit.get_owner_actor())
	if side == -1:
		push_warning("CombatManager | Unit owner is not part of this contest")
		return
	if get_contest().get_units(side).size() >= get_max_units(side):
		print("CombatManager | %s already has the maximum number of units selected" % Contest.Side.find_key(side))
		return
	get_contest().add_unit(side, unit)


func deselect_unit(unit: UnitInstance) -> void:
	var side := get_contest().get_side_of(unit.get_owner_actor())
	if side == -1:
		push_warning("CombatManager | Actor attempted to deselect a unit outside this contest")
		return
	get_contest().remove_unit(side, unit)


func set_actor_ready(actor: Actor) -> void:
	var side := get_contest().get_side_of(actor)
	if side == -1:
		push_warning("CombatManager | Actor outside of combat declared ready")
		return
	get_contest().set_ready(side, true)
	if get_contest().are_both_sides_ready():
		_run_damage_phase()


func set_actor_not_ready(actor: Actor) -> void:
	var side := get_contest().get_side_of(actor)
	if side == -1:
		push_warning("CombatManager | Actor outside of combat declared not ready")
		return
	get_contest().set_ready(side, false)
#endregion


#region Accessors
func get_contest() -> Contest:
	return AbilitySystem.resolve_get(self, &"contest", _contest)


func set_contest(value: Contest) -> void:
	_contest = AbilitySystem.resolve_set(self, &"contest", _contest, value)


func get_phase() -> CombatPhase:
	return _phase


func get_max_units(side: Contest.Side) -> int:
	return AbilitySystem.resolve_get(self, _side_key(side, "units"), _max_units[side])


func set_max_units(side: Contest.Side, value: int) -> void:
	_max_units[side] = AbilitySystem.resolve_set(self, _side_key(side, "units"), _max_units[side], value)


func get_max_abilities(side: Contest.Side) -> int:
	return AbilitySystem.resolve_get(self, _side_key(side, "abilities"), _max_abilities[side])


func set_max_abilities(side: Contest.Side, value: int) -> void:
	_max_abilities[side] = AbilitySystem.resolve_set(self, _side_key(side, "abilities"), _max_abilities[side], value)
#endregion


#region Private
func _run_damage_phase() -> void:
	if _phase != CombatPhase.SELECT:
		push_warning("CombatManager | Damage phase requested outside of the select phase")
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

	var all_outcomes: Array[CombatOutcome] = []
	all_outcomes.append_array(attacker_outcomes)
	all_outcomes.append_array(defender_outcomes)
	combat_resolved.emit(all_outcomes)
	_outcome_emitted = true

	_remove_dead(attacker_outcomes, contest.get_lander(Contest.Side.ATTACKER))
	_remove_dead(defender_outcomes, contest.get_lander(Contest.Side.DEFENDER))

	_phase = CombatPhase.CLEANUP


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
func _side_key(side: Contest.Side, field: String) -> StringName:
	return StringName("max_" + ("attacker_" if side == Contest.Side.ATTACKER else "defender_") + field)
#endregion
