# building_instance.gd
class_name BuildingInstance
extends RefCounted

## A building standing on a lander. Stats come from a shared BuildingData but are
## read through this instance so abilities can affect one building on its own.

var _building_data: BuildingData
var _owner_actor: Actor
var _hit_points: int = 1
## Node the building's mesh is spawned under (the lander's "Building" node).
var _mesh_parent: Node3D


func _init(building_data: BuildingData = null, owner_actor: Actor = null) -> void:
	_building_data = building_data
	_owner_actor = owner_actor


#region Public API
func bind_mesh_parent(mesh_parent: Node3D) -> void:
	_mesh_parent = mesh_parent


## Replaces whatever is under the mesh parent with this building's mesh.
func refresh_mesh() -> void:
	for child in _mesh_parent.get_children():
		child.queue_free()
	_mesh_parent.add_child(get_mesh_scene().instantiate())


func has_purchases() -> bool:
	return not get_upgrades().is_empty() or not get_spawnable_unit_types().is_empty()
#endregion


#region Accessors
func get_building_data() -> BuildingData:
	return AbilitySystem.resolve_get(self, &"building_data", _building_data)


func set_building_data(value: BuildingData) -> void:
	_building_data = AbilitySystem.resolve_set(self, &"building_data", _building_data, value)


func get_owner_actor() -> Actor:
	return AbilitySystem.resolve_get(self, &"owner_actor", _owner_actor)


func set_owner_actor(value: Actor) -> void:
	_owner_actor = AbilitySystem.resolve_set(self, &"owner_actor", _owner_actor, value)


func get_hit_points() -> int:
	return AbilitySystem.resolve_get(self, &"hit_points", _hit_points)


func set_hit_points(value: int) -> void:
	_hit_points = AbilitySystem.resolve_set(self, &"hit_points", _hit_points, value)


# --- Per-instance views of BuildingData stats ---

func get_display_name() -> String:
	return AbilitySystem.resolve_get(self, &"display_name", get_building_data().get_display_name())


func get_mesh_scene() -> PackedScene:
	return AbilitySystem.resolve_get(self, &"mesh_scene", get_building_data().get_mesh_scene())


func can_spawn_units() -> bool:
	return AbilitySystem.resolve_get(self, &"can_spawn", get_building_data().can_spawn_units())


func get_spawnable_unit_types() -> Array[UnitData.UnitType]:
	return AbilitySystem.resolve_get(self, &"spawnable_unit_types", get_building_data().get_spawnable_unit_types())


func get_upgrades() -> Array[BuildingData]:
	return AbilitySystem.resolve_get(self, &"upgrades", get_building_data().get_upgrades())
#endregion
