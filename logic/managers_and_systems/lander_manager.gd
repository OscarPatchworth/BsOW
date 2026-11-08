# lander_manager.gd
class_name LanderManager
extends Node

## Spawns landers, answers spatial questions about them, and executes lander-level actions.
## All distances are measured on the board (flat, ignoring height): see Lander.get_board_position.

## A lander was added to the board (the GravitySystem pulls landers together after this).
signal lander_spawned(lander: Lander)
## Two landers hit each other. Emitted once per crash.
signal landers_crashed(first: Lander, second: Lander, impact_speed: float)

const LANDER_RADIUS: float = 1.0
const MIN_DISTANCE_BETWEEN_LANDERS: float = 2.0
const MIN_DISTANCE_SQUARED: float = MIN_DISTANCE_BETWEEN_LANDERS ** 2
## Landers spawn slightly above the floor and drop into place.
const SPAWN_OFFSET: Vector3 = Vector3.UP * 0.4
## Protected (AI) landers are garrisoned with units that inherit from this.
const GARRISON_BASE_UNIT: UnitData = preload("res://data/units/base_footsoldier.tres")

@export var lander_scene: PackedScene
## Biomes picked from at random when a lander is placed without a chosen biome.
@export var random_biome_pool: Array[BiomeData] = []
## Landers closer than this are connected (units can move/attack between them).
@export var connected_lander_distance: float = 2.5

var _landers: Array[Lander] = []
var _landers_root: Node3D
## Actor -> BiomeData: the biome of that actor's next dustcloud lander, rolled in advance so
## the player can see what they're about to place.
var _next_biomes := {}


#region Public API
func bind_landers_root(landers_root: Node3D) -> void:
	_landers_root = landers_root


func spawn_random_lander(position: Vector3) -> Lander:
	return _spawn_lander(position, random_biome_pool.pick_random())


## The biome `actor`'s next PLACE_LANDER will have (rolled now if it hasn't been yet).
func peek_next_biome(actor: Actor) -> BiomeData:
	if not _next_biomes.has(actor):
		_next_biomes[actor] = random_biome_pool.pick_random()
	return _next_biomes[actor]


## Spawns `actor`'s next lander (the biome peek_next_biome showed), then rolls the one after.
func spawn_next_lander_for(actor: Actor, position: Vector3) -> Lander:
	var biome := peek_next_biome(actor)
	_next_biomes.erase(actor)
	return _spawn_lander(position, biome)


func spawn_biome_lander(action: Action) -> Lander:
	return _spawn_lander(action.get_position(), action.get_biome_data())


## Spawns a random lander already garrisoned by `owner_actor`.
func spawn_protected_lander(position: Vector3, owner_actor: Actor, defender_count: int) -> Lander:
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
	return lander


func is_valid_lander_placement(position: Vector3) -> bool:
	return is_position_clear(position)


## True if no lander is within MIN_DISTANCE_BETWEEN_LANDERS of `position`.
func is_position_clear(position: Vector3) -> bool:
	var spot := _flat(position)
	for lander in get_landers():
		if spot.distance_squared_to(lander.get_board_position()) < MIN_DISTANCE_SQUARED:
			return false
	return true


## True if `position` is within connection range of any lander.
func is_position_adjacent(position: Vector3) -> bool:
	return not get_landers_within(position, get_connected_lander_distance()).is_empty()


## Landers whose board position is within `radius` of `position`.
func get_landers_within(position: Vector3, radius: float, exclude: Lander = null) -> Array[Lander]:
	var spot := _flat(position)
	var found: Array[Lander] = []
	for lander in get_landers():
		if lander != exclude and spot.distance_squared_to(lander.get_board_position()) < radius * radius:
			found.append(lander)
	return found


func get_connected_landers(lander: Lander) -> Array[Lander]:
	var connected := get_landers_within(lander.get_board_position(), get_connected_lander_distance(), lander)
	return AbilitySystem.resolve_get(self, &"connected_landers", connected)


func are_connected(first: Lander, second: Lander) -> bool:
	return second in get_connected_landers(first)


func get_landers_owned_by(actor: Actor) -> Array[Lander]:
	var owned: Array[Lander] = []
	for lander in get_landers():
		if lander.get_owner_actor() == actor:
			owned.append(lander)
	return owned


func move_units(action: Action) -> void:
	action.get_source_lander().remove_units(action.get_units())
	action.get_target_lander().add_units(action.get_units())


## Removes everything `actor` has on the board (when they're eliminated): their units leave
## and their buildings are razed, so their landers become neutral.
func remove_assets_of(actor: Actor) -> void:
	for lander in get_landers():
		var their_units: Array[UnitInstance] = []
		for unit in lander.get_units():
			if unit.get_owner_actor() == actor:
				their_units.append(unit)
		if not their_units.is_empty():
			lander.remove_units(their_units)
		if lander.has_building() and lander.get_building().get_owner_actor() == actor:
			lander.remove_building()


## Pays `actor` the upkeep of every lander they own.
func run_upkeep(actor: Actor) -> void:
	var wallet := actor.get_wallet()
	for lander in get_landers_owned_by(actor):
		wallet.add(lander.get_upkeep())
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
	lander.crashed_into.connect(_on_lander_crashed_into.bind(lander))
	_landers_root.add_child(lander)
	_landers.append(lander)
	lander_spawned.emit(lander)
	return lander


func _flat(position: Vector3) -> Vector3:
	return Vector3(position.x, 0, position.z)
#endregion


#region Signal handlers
## Both landers report a crash; pass it on once.
func _on_lander_crashed_into(other: Lander, impact_speed: float, lander: Lander) -> void:
	if lander.get_instance_id() < other.get_instance_id():
		landers_crashed.emit(lander, other, impact_speed)
#endregion
