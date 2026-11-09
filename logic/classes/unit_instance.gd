# unit_instance.gd
class_name UnitInstance
extends RefCounted

## A unit on the board. Its stats come from a shared UnitData, but they are read
## through this instance so abilities can change one unit without touching the others.

var _unit_data: UnitData
var _owner_actor: Actor
var _hit_points: int = 1
## Units move one lander per turn: set by MOVE_UNITS, cleared at the owner's upkeep.
var _has_moved: bool = false


func _init(unit_data: UnitData = null, owner_actor: Actor = null) -> void:
	_unit_data = unit_data
	_owner_actor = owner_actor


#region Accessors
func get_unit_data() -> UnitData:
	return AbilitySystem.resolve_get(self, &"unit_data", _unit_data)


func set_unit_data(value: UnitData) -> void:
	_unit_data = AbilitySystem.resolve_set(self, &"unit_data", _unit_data, value)


func get_owner_actor() -> Actor:
	return AbilitySystem.resolve_get(self, &"owner_actor", _owner_actor)


func set_owner_actor(value: Actor) -> void:
	_owner_actor = AbilitySystem.resolve_set(self, &"owner_actor", _owner_actor, value)


func get_hit_points() -> int:
	return AbilitySystem.resolve_get(self, &"hit_points", _hit_points)


func set_hit_points(value: int) -> void:
	_hit_points = AbilitySystem.resolve_set(self, &"hit_points", _hit_points, value)


## True once this unit has moved this turn (it can't move again until its owner's next upkeep).
func has_moved() -> bool:
	return AbilitySystem.resolve_get(self, &"has_moved", _has_moved)


func set_has_moved(value: bool) -> void:
	_has_moved = AbilitySystem.resolve_set(self, &"has_moved", _has_moved, value)


# --- Per-instance views of UnitData stats ---

func get_display_name() -> String:
	return AbilitySystem.resolve_get(self, &"display_name", get_unit_data().get_display_name())


func get_icon() -> Texture2D:
	return AbilitySystem.resolve_get(self, &"icon", get_unit_data().get_icon())


func get_mesh_scene() -> PackedScene:
	return AbilitySystem.resolve_get(self, &"mesh_scene", get_unit_data().get_mesh_scene())


func get_unit_type() -> UnitData.UnitType:
	return AbilitySystem.resolve_get(self, &"unit_type", get_unit_data().get_unit_type())


func get_damage() -> DamageData:
	return AbilitySystem.resolve_get(self, &"damage", get_unit_data().get_damage())


func can_build_buildings() -> bool:
	return AbilitySystem.resolve_get(self, &"can_build", get_unit_data().can_build_buildings())


func get_buildables() -> Array[BuildingData]:
	return AbilitySystem.resolve_get(self, &"buildables", get_unit_data().get_buildables())
#endregion
