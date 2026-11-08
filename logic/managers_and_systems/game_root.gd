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

	_combat_manager.bind_match_settings(_match_settings)

	_lander_manager.bind_landers_root(_landers_root)
	_lander_manager.spawn_random_lander(Vector3.ZERO)

	# Order matters: the lander is built before setup is finished.
	_action_manager.build_approved.connect(_lander_manager.build)
	_action_manager.build_approved.connect(_on_action_manager_build_approved)
	_action_manager.unit_purchase_approved.connect(_lander_manager.buy_unit)
	_action_manager.biome_placement_approved.connect(_lander_manager.spawn_biome_lander)
	_action_manager.turn_progress_approved.connect(_turn_manager.progress_phase)

	_turn_manager.game_phase_changed.connect(_on_turn_manager_game_phase_changed)
	root_setup_finished.connect(_turn_manager.start)
#endregion


#region Actors
func _add_player() -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	_bind_actor(player)
	player.bind_draw_3d(_draw_3d)
	player.bind_match_settings(_match_settings)

	# Player -> game
	player.action_requested.connect(_action_manager.request_action)
	player.combat_selection_requested.connect(_combat_manager.request_selection)

	# Game -> player
	_lander_manager.building_built.connect(player._on_lander_manager_building_built)
	_lander_manager.unit_bought.connect(player._on_lander_manager_unit_bought)
	_lander_manager.units_moved.connect(player._on_lander_manager_units_moved)
	_combat_manager.combat_started.connect(player._on_combat_manager_combat_started)
	_combat_manager.combat_updated.connect(player._on_combat_manager_combat_updated)
	_combat_manager.combat_resolved.connect(player._on_combat_manager_combat_resolved)
	_turn_manager.game_state_changed.connect(player._on_turn_manager_game_state_changed)
	_turn_manager.game_phase_changed.connect(player._on_turn_manager_game_phase_changed)
	_turn_manager.turn_order_generated.connect(player._on_turn_manager_turn_order_generated)
	_turn_manager.active_actor_changed.connect(player._on_turn_manager_active_actor_changed)
	_turn_manager.season_order_generated.connect(player._on_turn_manager_season_order_generated)
	_turn_manager.season_changed.connect(player._on_turn_manager_season_changed)
	_action_manager.biome_placement_approved.connect(player._on_action_manager_biome_placement_approved)
	_action_manager.build_approved.connect(player._on_action_manager_build_approved)

	_actors_root.add_child(player)
	_turn_manager.register_actor(player)


func _add_ai() -> void:
	var ai := SimpleAI.new()
	ai.name = "SimpleAI"
	_bind_actor(ai)

	_combat_manager.combat_started.connect(ai._on_combat_manager_combat_started)
	ai.combat_unit_selected.connect(_combat_manager.select_unit)
	ai.combat_unit_deselected.connect(_combat_manager.deselect_unit)
	ai.combat_ready.connect(_combat_manager.set_actor_ready)
	ai.combat_not_ready.connect(_combat_manager.set_actor_not_ready)

	_spawn_ai_landers(ai)

	_actors_root.add_child(ai)
	_turn_manager.register_actor(ai)


## Gives an actor a random species, a starting wallet, and the managers it needs.
func _bind_actor(actor: Actor) -> void:
	actor.set_species(game_species.pick_random())
	actor.set_wallet(_create_starting_wallet())
	actor.bind_turn_manager(_turn_manager)
	actor.bind_lander_manager(_lander_manager)
	actor.bind_combat_manager(_combat_manager)


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


#region Signal handlers
func _on_action_manager_build_approved(_action: Action) -> void:
	# The first building during setup is the command tower, which ends setup.
	if _turn_manager.get_game_state() == TurnManager.GameState.SETUP:
		_turn_manager.finish_setup()


func _on_turn_manager_game_phase_changed(phase: TurnManager.Phase) -> void:
	if phase == TurnManager.Phase.UPKEEP:
		_lander_manager.run_upkeep(_turn_manager.get_active_actor())
#endregion
