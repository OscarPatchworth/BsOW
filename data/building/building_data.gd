# building_data.gd
class_name BuildingData
extends Resource

## Authored definition of a building. Runtime buildings are BuildingInstance.

@export var display_name: String
@export var cost: EconData
@export var mesh_scene: PackedScene
@export var icon: Texture2D
@export var is_unique := false
@export var overrides_unit_capacity := false
@export var unit_capacity := -1
@export var can_spawn := false
@export var spawnable_unit_types: Array[UnitData.UnitType] = []
@export var can_upgrade := false
@export var upgrades: Array[BuildingData] = []


#region Accessors
func get_display_name() -> String:
	return AbilitySystem.resolve_get(self, &"display_name", display_name)


func get_cost() -> EconData:
	return AbilitySystem.resolve_get(self, &"cost", cost)


func get_mesh_scene() -> PackedScene:
	return AbilitySystem.resolve_get(self, &"mesh_scene", mesh_scene)


func get_icon() -> Texture2D:
	return AbilitySystem.resolve_get(self, &"icon", icon)


func is_unique_building() -> bool:
	return AbilitySystem.resolve_get(self, &"is_unique", is_unique)


func does_override_unit_capacity() -> bool:
	return AbilitySystem.resolve_get(self, &"overrides_unit_capacity", overrides_unit_capacity)


func get_unit_capacity() -> int:
	return AbilitySystem.resolve_get(self, &"unit_capacity", unit_capacity)


func can_spawn_units() -> bool:
	return AbilitySystem.resolve_get(self, &"can_spawn", can_spawn)


func get_spawnable_unit_types() -> Array[UnitData.UnitType]:
	return AbilitySystem.resolve_get(self, &"spawnable_unit_types", spawnable_unit_types)


func can_be_upgraded() -> bool:
	return AbilitySystem.resolve_get(self, &"can_upgrade", can_upgrade)


func get_upgrades() -> Array[BuildingData]:
	return AbilitySystem.resolve_get(self, &"upgrades", upgrades)
#endregion
