# unit_data.gd
class_name UnitData
extends Resource

## Authored definition of a unit. Runtime units are UnitInstance.
## Any field left empty is inherited from `base` (if set).

enum UnitType {
	NULL = -1,
	MELEE_BASIC,
	MELEE_ADVANCED,
	RANGED_BASIC,
	RANGED_ADVANCED,
	SPECIAL,
}

@export var base: UnitData
@export var display_name: String
@export var mesh_scene: PackedScene
@export var icon: Texture2D
@export var cost: EconData
@export var unit_type: UnitType = UnitType.NULL
@export var damage: DamageData
@export var can_build := false
@export var buildables: Array[BuildingData] = []


#region Public API
## True if this unit is `other`, or inherits from it somewhere up the `base` chain.
func is_or_inherits(other: UnitData) -> bool:
	var current: UnitData = self
	while current != null:
		if current == other:
			return true
		current = current.get_base()
	return false
#endregion


#region Accessors
func get_base() -> UnitData:
	return AbilitySystem.resolve_get(self, &"base", base)


func get_display_name() -> String:
	return AbilitySystem.resolve_get(self, &"display_name", display_name)


func get_mesh_scene() -> PackedScene:
	var value: PackedScene = mesh_scene
	if value == null and get_base() != null:
		value = get_base().get_mesh_scene()
	if value == null:
		push_warning("UnitData | '%s' has no mesh_scene and no base to inherit one from" % display_name)
	return AbilitySystem.resolve_get(self, &"mesh_scene", value)


func get_icon() -> Texture2D:
	var value: Texture2D = icon
	if value == null and get_base() != null:
		value = get_base().get_icon()
	return AbilitySystem.resolve_get(self, &"icon", value)


func get_cost() -> EconData:
	var value: EconData = cost
	if value == null and get_base() != null:
		value = get_base().get_cost()
	return AbilitySystem.resolve_get(self, &"cost", value)


func get_unit_type() -> UnitType:
	var value: UnitType = unit_type
	if value == UnitType.NULL and get_base() != null:
		value = get_base().get_unit_type()
	return AbilitySystem.resolve_get(self, &"unit_type", value)


func get_damage() -> DamageData:
	var value: DamageData = damage
	if value == null and get_base() != null:
		value = get_base().get_damage()
	return AbilitySystem.resolve_get(self, &"damage", value)


func can_build_buildings() -> bool:
	return AbilitySystem.resolve_get(self, &"can_build", can_build)


func get_buildables() -> Array[BuildingData]:
	var value: Array[BuildingData] = buildables
	if value.is_empty() and get_base() != null:
		value = get_base().get_buildables()
	return AbilitySystem.resolve_get(self, &"buildables", value)
#endregion
