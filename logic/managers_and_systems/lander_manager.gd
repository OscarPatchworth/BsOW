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
## Physics layer of the invisible board walls (landers collide with it; mouse rays don't).
const WALL_LAYER: int = 4
const WALL_HEIGHT: float = 4.0
const WALL_THICKNESS: float = 1.0
## Protected (AI) landers are garrisoned with units that inherit from this.
const GARRISON_BASE_UNIT: UnitData = preload("res://data/units/base_footsoldier.tres")

@export var lander_scene: PackedScene
## Biomes picked from at random when a lander is placed without a chosen biome.
@export var random_biome_pool: Array[BiomeData] = []
## Landers closer than this are connected (units can move/attack between them).
@export var connected_lander_distance: float = 2.5
## The play area is the square ±board_half_size around the origin (the floor's edge).
## Invisible walls stand there and landers can't be placed with any part outside it.
@export var board_half_size: float = 20.0

var _landers: Array[Lander] = []
var _landers_root: Node3D
## Actor -> BiomeData: the biome of that actor's next dustcloud lander, rolled in advance so
## the player can see what they're about to place.
var _next_biomes := {}
## Lander -> Actor: who placed each setup (PLACE_BIOME) lander. Their command tower goes on one.
var _setup_placers := {}


#region Public API
func bind_landers_root(landers_root: Node3D) -> void:
	_landers_root = landers_root
	_build_walls()


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
	var lander := _spawn_lander(action.get_position(), action.get_biome_data())
	_setup_placers[lander] = action.get_actor()
	return lander


## The landers `actor` placed during setup (that are still on the board).
func get_setup_landers_of(actor: Actor) -> Array[Lander]:
	var placed: Array[Lander] = []
	for lander in get_landers():
		if _setup_placers.get(lander) == actor:
			placed.append(lander)
	return placed


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
	return get_placement_problem(position) == ""


## Why a lander can't go at `position` ("" if it can).
func get_placement_problem(position: Vector3) -> String:
	if not is_inside_board(position):
		return "Outside the play area"
	if not is_position_clear(position):
		return "Too close to another lander"
	return ""


## True if a whole lander centred at `position` fits inside the walls.
func is_inside_board(position: Vector3) -> bool:
	var limit := board_half_size - LANDER_RADIUS
	return absf(position.x) <= limit and absf(position.z) <= limit


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


## Four invisible walls around the play area, so landers can't slide off the board.
func _build_walls() -> void:
	if _landers_root == null or _landers_root.has_node("BoardWalls"):
		return
	var walls := StaticBody3D.new()
	walls.name = "BoardWalls"
	walls.collision_layer = WALL_LAYER
	walls.collision_mask = 0
	var length := (board_half_size + WALL_THICKNESS) * 2.0
	var offset := board_half_size + WALL_THICKNESS * 0.5
	for side: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var box := BoxShape3D.new()
		box.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, length) if side.x != 0.0 else Vector3(length, WALL_HEIGHT, WALL_THICKNESS)
		var shape := CollisionShape3D.new()
		shape.shape = box
		shape.position = side * offset + Vector3.UP * WALL_HEIGHT * 0.5
		walls.add_child(shape)
	_landers_root.add_child(walls)


func _flat(position: Vector3) -> Vector3:
	return Vector3(position.x, 0, position.z)
#endregion


#region Signal handlers
## Both landers report a crash; pass it on once.
func _on_lander_crashed_into(other: Lander, impact_speed: float, lander: Lander) -> void:
	if lander.get_instance_id() < other.get_instance_id():
		landers_crashed.emit(lander, other, impact_speed)
#endregion
