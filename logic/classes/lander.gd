# lander.gd
class_name Lander
extends RigidBody3D

## A tile on the board. Holds a biome, at most one building, and a group of units.

signal building_built(action: Action)
signal unit_bought(action: Action)

const DEFAULT_UNIT_CAPACITY: int = 5
const UNIT_SPREAD_RADIUS: float = 0.7

@export var biome_mesh: CSGMesh3D

var _biome_data: BiomeData
var _building: BuildingInstance
var _units: Array[UnitInstance] = []
var _unit_capacity: int = DEFAULT_UNIT_CAPACITY

@onready var _building_node: Node3D = find_child("Building")
@onready var _units_node: Node3D = find_child("Units")


#region Public API
## Builds `action`'s building (building_data, or the purchasable) for the action's actor.
func build(action: Action) -> void:
	var building_data: BuildingData = action.get_building_data()
	if building_data == null:
		building_data = action.get_purchasable() as BuildingData
	if building_data == null:
		push_warning("Lander | build() called without a BuildingData")
		return

	var building := BuildingInstance.new(building_data, action.get_actor())
	building.bind_mesh_parent(_building_node)
	set_building(building)
	building.refresh_mesh()
	building_built.emit(action)


## Spawns `action`'s unit (unit_data, or the purchasable) for the action's actor.
func buy_unit(action: Action) -> void:
	var unit_data: UnitData = action.get_unit_data()
	if unit_data == null:
		unit_data = action.get_purchasable() as UnitData
	if unit_data == null:
		push_warning("Lander | buy_unit() called without a UnitData")
		return

	add_units([UnitInstance.new(unit_data, action.get_actor())] as Array[UnitInstance])
	unit_bought.emit(action)


func add_units(new_units: Array[UnitInstance]) -> void:
	var units := get_units().duplicate()
	for unit in new_units:
		if unit in units:
			push_warning("Lander | Unit is already on this lander")
			continue
		units.append(unit)
	set_units(units)


func remove_units(units_to_remove: Array[UnitInstance]) -> void:
	var units := get_units().duplicate()
	for unit in units_to_remove:
		if unit not in units:
			push_warning("Lander | Unit is not on this lander")
			continue
		units.erase(unit)
	set_units(units)


func has_building() -> bool:
	return get_building() != null


func has_units() -> bool:
	return not get_units().is_empty()


func is_full() -> bool:
	return get_units().size() >= get_unit_capacity()


## Everything `actor` could buy on this lander right now:
## building upgrades, units the building can spawn, and buildings the units can build.
func get_purchasables(actor: Actor) -> Array[Resource]:
	var purchasables: Array[Resource] = []
	var building := get_building()

	if building != null:
		purchasables.append_array(building.get_upgrades())
		var spawnable_types := building.get_spawnable_unit_types()
		for unit_data in actor.get_species().get_units():
			if unit_data.get_unit_type() in spawnable_types:
				purchasables.append(unit_data)
	else:
		for unit in get_units():
			for building_data in unit.get_buildables():
				if building_data not in purchasables:
					purchasables.append(building_data)

	return AbilitySystem.resolve_get(self, &"purchasables", purchasables)
#endregion


#region Accessors
func get_biome_data() -> BiomeData:
	return AbilitySystem.resolve_get(self, &"biome_data", _biome_data)


func set_biome_data(value: BiomeData) -> void:
	_biome_data = AbilitySystem.resolve_set(self, &"biome_data", _biome_data, value)
	_refresh_biome_mesh()


func get_building() -> BuildingInstance:
	return AbilitySystem.resolve_get(self, &"building", _building)


func set_building(value: BuildingInstance) -> void:
	_building = AbilitySystem.resolve_set(self, &"building", _building, value)


func get_units() -> Array[UnitInstance]:
	return AbilitySystem.resolve_get(self, &"units", _units)


func set_units(value: Array[UnitInstance]) -> void:
	_units = AbilitySystem.resolve_set(self, &"units", _units, value)
	_refresh_unit_meshes()


func get_unit_capacity() -> int:
	return AbilitySystem.resolve_get(self, &"unit_capacity", _unit_capacity)


func set_unit_capacity(value: int) -> void:
	_unit_capacity = AbilitySystem.resolve_set(self, &"unit_capacity", _unit_capacity, value)


## The building's owner if there is a building, otherwise the owner of the units, otherwise null.
func get_owner_actor() -> Actor:
	var owner_actor: Actor = null
	if get_building() != null:
		owner_actor = get_building().get_owner_actor()
	elif has_units():
		owner_actor = get_units()[0].get_owner_actor()
	return AbilitySystem.resolve_get(self, &"owner_actor", owner_actor)


func get_upkeep() -> EconData:
	return AbilitySystem.resolve_get(self, &"upkeep", get_biome_data().get_upkeep())
#endregion


#region Private
func _refresh_biome_mesh() -> void:
	biome_mesh.material = get_biome_data().get_mesh_material()


func _refresh_unit_meshes() -> void:
	if _units_node == null:
		return  # Not in the tree yet, so there is nothing to draw into.
	for child in _units_node.get_children():
		child.queue_free()
	for unit in get_units():
		var unit_mesh: Node3D = unit.get_mesh_scene().instantiate()
		var angle := randf() * TAU
		unit_mesh.position += Vector3(cos(angle), 0, sin(angle)) * UNIT_SPREAD_RADIUS
		_units_node.add_child(unit_mesh)
#endregion
