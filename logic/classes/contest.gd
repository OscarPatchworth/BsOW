# contest.gd
class_name Contest
extends RefCounted

## The state of one fight: an attacking lander invading a defending lander.
## Most accessors take a `side` so callers don't need attacker/defender branches.
## `side` parameters are typed int (holding a Contest.Side value) because Godot can mis-resolve
## the enum type when Contest is loaded through a cyclic class reference.

enum Side {
	ATTACKER,
	DEFENDER,
}

var _landers := {Side.ATTACKER: null, Side.DEFENDER: null}
var _units := {Side.ATTACKER: [] as Array[UnitInstance], Side.DEFENDER: [] as Array[UnitInstance]}
var _ready_flags := {Side.ATTACKER: false, Side.DEFENDER: false}


func _init(attacker_lander: Lander = null, defender_lander: Lander = null) -> void:
	_landers[Side.ATTACKER] = attacker_lander
	_landers[Side.DEFENDER] = defender_lander


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


func to_debug_dictionary() -> Dictionary:
	return {
		"attacker_lander": get_lander(Side.ATTACKER),
		"defender_lander": get_lander(Side.DEFENDER),
		"attacker_units": get_units(Side.ATTACKER),
		"defender_units": get_units(Side.DEFENDER),
		"attacker_ready": is_ready(Side.ATTACKER),
		"defender_ready": is_ready(Side.DEFENDER),
	}
#endregion


#region Accessors
func get_lander(side: int) -> Lander:
	return AbilitySystem.resolve_get(self, _key(side, "lander"), _landers[side])


func set_lander(side: int, value: Lander) -> void:
	_landers[side] = AbilitySystem.resolve_set(self, _key(side, "lander"), _landers[side], value)


## The actor fighting on `side`: whoever owns the units on that side's lander.
func get_actor(side: int) -> Actor:
	var lander := get_lander(side)
	var actor: Actor = null
	if lander != null:
		var lander_units := lander.get_units()
		actor = lander_units[0].get_owner_actor() if not lander_units.is_empty() else lander.get_owner_actor()
	return AbilitySystem.resolve_get(self, _key(side, "actor"), actor)


## Units chosen to fight on `side`.
func get_units(side: int) -> Array[UnitInstance]:
	return AbilitySystem.resolve_get(self, _key(side, "units"), _units[side])


func set_units(side: int, value: Array[UnitInstance]) -> void:
	_units[side] = AbilitySystem.resolve_set(self, _key(side, "units"), _units[side], value)


func is_ready(side: int) -> bool:
	return AbilitySystem.resolve_get(self, _key(side, "ready"), _ready_flags[side])


func set_ready(side: int, value: bool) -> void:
	_ready_flags[side] = AbilitySystem.resolve_set(self, _key(side, "ready"), _ready_flags[side], value)
#endregion


#region Private
## e.g. (ATTACKER, "units") -> &"attacker_units"
func _key(side: int, field: String) -> StringName:
	return StringName(("attacker_" if side == Side.ATTACKER else "defender_") + field)
#endregion
