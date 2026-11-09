# contest.gd
class_name Contest
extends RefCounted

## The state of one battle: an attacking lander invading a defending lander.
## A battle runs in rounds: both sides pick units and ready up, dice are rolled, the dead are
## removed, and if both sides still have units the next round starts with the survivors still
## selected. It ends when a side is wiped out, the attacker retreats, or MAX_ROUNDS is reached.
## Most accessors take a `side` so callers don't need attacker/defender branches.
## `side` parameters are typed int (holding a Contest.Side value) because Godot can mis-resolve
## the enum type when Contest is loaded through a cyclic class reference.

enum Side {
	ATTACKER,
	DEFENDER,
}

enum Result {
	ONGOING,
	ATTACKER_WON,  ## The defending lander has no units left.
	DEFENDER_WON,  ## The attacking lander has no units left.
	RETREATED,     ## The attacker called it off.
	STALEMATE,     ## Neither side was wiped out within MAX_ROUNDS.
}

var _landers := {Side.ATTACKER: null, Side.DEFENDER: null}
var _units := {Side.ATTACKER: [] as Array[UnitInstance], Side.DEFENDER: [] as Array[UnitInstance]}
var _ready_flags := {Side.ATTACKER: false, Side.DEFENDER: false}
## Fixed when the battle starts, so a side keeps its actor after its units are wiped out.
var _actors := {Side.ATTACKER: null, Side.DEFENDER: null}
var _round: int = 1
var _result: Result = Result.ONGOING
var _last_outcomes: Array[CombatOutcome] = []
var _last_notes: Array[String] = []


func _init(attacker_lander: Lander = null, defender_lander: Lander = null) -> void:
	_landers[Side.ATTACKER] = attacker_lander
	_landers[Side.DEFENDER] = defender_lander
	for side in [Side.ATTACKER, Side.DEFENDER]:
		var lander: Lander = _landers[side]
		if lander != null:
			var lander_units := lander.get_units()
			_actors[side] = lander_units[0].get_owner_actor() if not lander_units.is_empty() else lander.get_owner_actor()


#region Public API
static func get_opposite_side(side: int) -> int:
	return Side.DEFENDER if side == Side.ATTACKER else Side.ATTACKER


## The side `actor` is fighting on, or -1 if they are not part of this contest.
func get_side_of(actor: Actor) -> int:
	if actor == null:
		return -1
	if get_actor(Side.ATTACKER) == actor:
		return Side.ATTACKER
	if get_actor(Side.DEFENDER) == actor:
		return Side.DEFENDER
	return -1


func is_involved(actor: Actor) -> bool:
	return get_side_of(actor) != -1


func add_unit(side: int, unit: UnitInstance) -> void:
	var units := get_units(side).duplicate()
	units.append(unit)
	set_units(side, units)


func remove_unit(side: int, unit: UnitInstance) -> void:
	var units := get_units(side).duplicate()
	units.erase(unit)
	set_units(side, units)


func are_both_sides_ready() -> bool:
	return is_ready(Side.ATTACKER) and is_ready(Side.DEFENDER)


func is_over() -> bool:
	return get_result() != Result.ONGOING


## Units still standing on `side`'s lander (whether selected or not).
func get_available_units(side: int) -> Array[UnitInstance]:
	var lander := get_lander(side)
	return lander.get_units() if lander != null else [] as Array[UnitInstance]


## Starts the next round: drops dead units from the selections and clears both ready flags.
func begin_next_round() -> void:
	for side in [Side.ATTACKER, Side.DEFENDER]:
		var alive: Array[UnitInstance] = []
		for unit in get_units(side):
			if unit in get_available_units(side):
				alive.append(unit)
		set_units(side, alive)
		set_ready(side, false)
	set_round(get_round() + 1)


func to_debug_dictionary() -> Dictionary:
	return {
		"attacker_lander": get_lander(Side.ATTACKER),
		"defender_lander": get_lander(Side.DEFENDER),
		"attacker_units": get_units(Side.ATTACKER),
		"defender_units": get_units(Side.DEFENDER),
		"attacker_ready": is_ready(Side.ATTACKER),
		"defender_ready": is_ready(Side.DEFENDER),
		"round": get_round(),
		"result": Result.find_key(get_result()),
	}
#endregion


#region Accessors
func get_lander(side: int) -> Lander:
	return AbilitySystem.resolve_get(self, _key(side, "lander"), _landers[side])


func set_lander(side: int, value: Lander) -> void:
	_landers[side] = AbilitySystem.resolve_set(self, _key(side, "lander"), _landers[side], value)


## The actor fighting on `side` (whoever owned that side's units when the battle started).
func get_actor(side: int) -> Actor:
	return AbilitySystem.resolve_get(self, _key(side, "actor"), _actors[side])


## Units chosen to fight on `side`.
func get_units(side: int) -> Array[UnitInstance]:
	return AbilitySystem.resolve_get(self, _key(side, "units"), _units[side])


func set_units(side: int, value: Array[UnitInstance]) -> void:
	_units[side] = AbilitySystem.resolve_set(self, _key(side, "units"), _units[side], value)


func is_ready(side: int) -> bool:
	return AbilitySystem.resolve_get(self, _key(side, "ready"), _ready_flags[side])


func set_ready(side: int, value: bool) -> void:
	_ready_flags[side] = AbilitySystem.resolve_set(self, _key(side, "ready"), _ready_flags[side], value)


func get_round() -> int:
	return AbilitySystem.resolve_get(self, &"round", _round)


func set_round(value: int) -> void:
	_round = AbilitySystem.resolve_set(self, &"round", _round, value)


func get_result() -> Result:
	return AbilitySystem.resolve_get(self, &"result", _result)


func set_result(value: Result) -> void:
	_result = AbilitySystem.resolve_set(self, &"result", _result, value)


## The outcomes of the most recent round (empty before the first roll).
## What abilities did after the last round (log lines), e.g. a Pack Call.
func get_last_notes() -> Array[String]:
	return _last_notes


func set_last_notes(value: Array[String]) -> void:
	_last_notes = value


func get_last_outcomes() -> Array[CombatOutcome]:
	return _last_outcomes


func set_last_outcomes(value: Array[CombatOutcome]) -> void:
	_last_outcomes = value
#endregion


#region Private
## e.g. (ATTACKER, "units") -> &"attacker_units"
func _key(side: int, field: String) -> StringName:
	return StringName(("attacker_" if side == Side.ATTACKER else "defender_") + field)
#endregion
