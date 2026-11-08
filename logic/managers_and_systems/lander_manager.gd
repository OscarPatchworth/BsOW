# lander_manager.gd
class_name LanderManager
extends Node

## Spawns landers, answers spatial questions about them, and executes lander-level actions.

signal building_built(action: Action)
signal unit_bought(action: Action)
signal units_moved(action: Action)
signal upkeep_completed()

const LANDER_RADIUS: float = 1.0
const MIN_DISTANCE_BETWEEN_LANDERS: float = 2.0
const MIN_DISTANCE_SQUARED: float = MIN_DISTANCE_BETWEEN_LANDERS ** 2
## Landers spawn slightly above the floor and drop into place.
const SPAWN_OFFSET: Vector3 = Vector3.UP * 2
## Protected (AI) landers are garrisoned with units that inherit from this.
const GARRISON_BASE_UNIT: UnitData = preload("res://data/units/base_footsoldier.tres")

@export var lander_scene: PackedScene
## Biomes picked from at random when a lander is placed without a chosen biome.
@export var random_biome_pool: Array[BiomeData] = []
## Landers closer than this are connected (units can move/attack between them).
@export var connected_lander_distance: float = 2.5

var _landers: Array[Lander] = []
var _landers_root: Node3D


#region Public API
func bind_landers_root(landers_root: Node3D) -> void:
	_landers_root = landers_root


func spawn_random_lander(position: Vector3) -> Lander:
	return _spawn_lander(position, random_biome_pool.pick_random())


func spawn_biome_lander(action: Action) -> Lander:
	return _spawn_lander(action.get_position(), action.get_biome_data())


## Spawns a random lander already garrisoned by `owner_actor`.
func spawn_protected_lander(position: Vector3, owner_actor: Actor, defender_count: int) -> void:
	var lander := spawn_random_lander(position)
	var garrison: Array[UnitInstance] = []
	for unit_data in owner_actor.get_species().get_units():
		if unit_data.get_base() != GARRISON_BASE_UNIT:
			continue
		for i in defender_count:
			garrison.append(UnitInstance.new(unit_data, owner_actor))
	if garrison.is_empty():
		push_warning("LanderManager | Species '%s' has no unit based on '%s'; protected lander is empty"
			% [owner_actor.get_species().get_display_name(), GARRISON_BASE_UNIT.get_display_name()])
	lander.add_units(garrison)


func is_valid_lander_placement(position: Vector3) -> bool:
	return is_position_clear(position)


## True if no lander is within MIN_DISTANCE_BETWEEN_LANDERS of `position`.
func is_position_clear(position: Vector3) -> bool:
	for lander in get_landers():
		if position.distance_squared_to(lander.position) < MIN_DISTANCE_SQUARED:
			return false
	return true


## True if `position` is within connection range of any lander.
func is_position_adjacent(position: Vector3) -> bool:
	var range_squared := get_connected_lander_distance() ** 2
	for lander in get_landers():
		if position.distance_squared_to(lander.position) < range_squared:
			return true
	return false


func get_connected_landers(lander: Lander) -> Array[Lander]:
	var range_squared := get_connected_lander_distance() ** 2
	var connected: Array[Lander] = []
	for other in get_landers():
		if other != lander and lander.position.distance_squared_to(other.position) < range_squared:
			connected.append(other)
	return AbilitySystem.resolve_get(self, &"connected_landers", connected)


func get_landers_owned_by(actor: Actor) -> Array[Lander]:
	var owned: Array[Lander] = []
	for lander in get_landers():
		if lander.get_owner_actor() == actor:
			owned.append(lander)
	return owned


func build(action: Action) -> void:
	action.get_target_lander().build(action)


func buy_unit(action: Action) -> void:
	action.get_target_lander().buy_unit(action)


func move_units(action: Action) -> void:
	action.get_source_lander().remove_units(action.get_units())
	action.get_target_lander().add_units(action.get_units())
	units_moved.emit(action)


## Pays `actor` the upkeep of every lander they own.
func run_upkeep(actor: Actor) -> void:
	var wallet := actor.get_wallet()
	for lander in get_landers_owned_by(actor):
		wallet.add(lander.get_upkeep())
	upkeep_completed.emit()
#endregion


#region Accessors
func get_landers() -> Array[Lander]:
	return AbilitySystem.resolve_get(self, &"landers", _landers)


func get_connected_lander_distance() -> float:
	return AbilitySystem.resolve_get(self, &"connected_lander_distance", connected_lander_distance)
#endregion


#region Private
func _spawn_lander(position: Vector3, biome_data: BiomeData) -> Lander:
	var lander: Lander = lander_scene.instantiate()
	lander.position = position + SPAWN_OFFSET
	lander.set_biome_data(biome_data)
	lander.building_built.connect(building_built.emit)
	lander.unit_bought.connect(unit_bought.emit)
	_landers_root.add_child(lander)
	_landers.append(lander)
	return lander
#endregion
