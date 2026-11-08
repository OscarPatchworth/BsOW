# game_root.gd
class_name GameRoot
extends Node3D

## Root of main.tscn. Creates the actors and wires every manager, actor and signal together.
## This is the only place that knows about everything; other scripts get what they need via bind_*().

signal root_setup_finished()

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

@export var game_species: Array[SpeciesData] = []

@onready var _action_manager: ActionManager = find_child("ActionManager")
@onready var _lander_manager: LanderManager = find_child("LanderManager")
@onready var _turn_manager: TurnManager = find_child("TurnManager")
@onready var _combat_manager: CombatManager = find_child("CombatManager")
@onready var _match_settings: MatchSettings = find_child("MatchSettings")
@onready var _draw_3d: Draw3D = find_child("Draw3D")
@onready var _actors_root: Node3D = find_child("Actors")
@onready var _landers_root: Node3D = find_child("Landers")


func _ready() -> void:
	_setup_managers()
	_add_player()
	_add_ai()
	root_setup_finished.emit()


#region Managers
func _setup_managers() -> void:
	_action_manager.bind_lander_manager(_lander_manager)
	_action_manager.bind_turn_manager(_turn_manager)
	_action_manager.bind_combat_manager(_combat_manager)
	_action_manager.bind_match_settings(_match_settings)

	_combat_manager.bind_match_settings(_match_settings)

	_lander_manager.bind_landers_root(_landers_root)
	_lander_manager.spawn_random_lander(Vector3.ZERO)

	root_setup_finished.connect(_turn_manager.start)
#endregion


#region Actors
func _add_player() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	player.bind_draw_3d(_draw_3d)
	player.bind_match_settings(_match_settings)
	_add_actor(player)


func _add_ai() -> void:
	var ai := SimpleAI.new()
	ai.name = "SimpleAI"
	_add_actor(ai)
	_spawn_ai_landers(ai)


## Every actor is set up the same way: a random species, a starting wallet, the managers,
## and its actions go to the ActionManager. Actors connect their own manager signals.
func _add_actor(actor: Actor) -> void:
	actor.set_species(game_species.pick_random())
	actor.set_wallet(_create_starting_wallet())
	actor.bind_action_manager(_action_manager)
	actor.bind_turn_manager(_turn_manager)
	actor.bind_lander_manager(_lander_manager)
	actor.bind_combat_manager(_combat_manager)
	actor.action_requested.connect(_action_manager.request_action)
	_actors_root.add_child(actor)
	_turn_manager.register_actor(actor)


func _create_starting_wallet() -> EconData:
	var wallet := EconData.new()
	for key in EconData.RESOURCE_KEYS:
		wallet.set_amount(key, _match_settings.get_starting_resource_amount())
	return wallet


func _spawn_ai_landers(ai: SimpleAI) -> void:
	var troop_count := _match_settings.get_ai_starting_troops()
	var map_size := _match_settings.get_map_size()
	for i in troop_count:
		var spawn_position := Vector3(
			randf() * map_size * (1 if randi() % 2 == 0 else -1),
			0,
			randf() * map_size * (1 if randi() % 2 == 0 else -1))
		if _lander_manager.is_position_clear(spawn_position):
			_lander_manager.spawn_protected_lander(spawn_position, ai, troop_count)
		else:
			print("GameRoot | AI lander spawn skipped: position overlaps another lander")
#endregion
