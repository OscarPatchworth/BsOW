# player_controller.gd
class_name PlayerController
extends Node3D

## Turns mouse input in the 3D world into selections and Actions for the local Player.

signal action_requested(action: Action)
signal lander_selected(lander: Lander)
signal lander_view_requested(lander: Lander)
signal movement_ui_requested(from_lander: Lander, to_lander: Lander)

enum ControllerState {
	IDLE,
	COLLAPSING_DUSTCLOUD,
	BUYING,
	MOVEMENT,
	COMBAT,
	DEAD,
	SETUP,
}

const RAYCAST_LENGTH: float = 100.0
const WORLD_SURFACE_LAYER: int = 1
const LANDER_LAYER: int = 2
const MOVEMENT_PREVIEW_INTERVAL: float = 1.0 / 30.0
const DUSTCLOUD_PREVIEW_INTERVAL: float = 1.0 / 60.0

var _player: Player
var _selector_manager: SelectorManager
var _turn_manager: TurnManager
var _lander_manager: LanderManager
var _draw_3d: Draw3D

var _state: ControllerState = ControllerState.IDLE
var _is_active_player: bool = false

# Movement state
var _is_dragging: bool = false
var _drag_start_lander: Lander
var _drag_end_lander: Lander
var _drag_connected_landers: Array[Lander] = []
var _movement_preview_timer: float = 0.0

# Dustcloud collapse state
var _dustcloud_preview_timer: float = 0.0

# Setup state
var _setup_selected_biome: BiomeData
var _is_placing_command_tower: bool = false

@onready var _camera: Camera3D = find_child("Camera3D")


func _input(event: InputEvent) -> void:
	match _state:
		ControllerState.COLLAPSING_DUSTCLOUD:
			_input_collapsing_dustcloud(event)
		ControllerState.MOVEMENT:
			_input_movement(event)
		ControllerState.SETUP:
			_input_setup(event)
		_:
			_input_idle(event)


func _process(delta: float) -> void:
	match _state:
		ControllerState.COLLAPSING_DUSTCLOUD:
			_process_collapsing_dustcloud(delta)
		ControllerState.MOVEMENT:
			_process_movement(delta)


#region Public API
func bind_player(player: Player) -> void:
	_player = player


func bind_selector_manager(selector_manager: SelectorManager) -> void:
	_selector_manager = selector_manager


func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager


func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_manager = lander_manager


func bind_draw_3d(draw_3d: Draw3D) -> void:
	_draw_3d = draw_3d


func apply_active_actor(active_actor: Actor) -> void:
	set_is_active_player(active_actor == _player)
	print("PlayerController | Active actor changed to: " + active_actor.name)


func apply_game_phase(phase: TurnManager.Phase) -> void:
	if not is_active_player():
		set_state(ControllerState.IDLE)
		return
	match phase:
		TurnManager.Phase.DUSTCLOUD_COLLAPSE:
			set_state(ControllerState.COLLAPSING_DUSTCLOUD)
		TurnManager.Phase.BUYING:
			set_state(ControllerState.BUYING)
		TurnManager.Phase.COMBAT:
			set_state(ControllerState.MOVEMENT)
		_:
			set_state(ControllerState.IDLE)


func apply_game_state(state: TurnManager.GameState) -> void:
	if state == TurnManager.GameState.SETUP:
		set_state(ControllerState.SETUP)


func enter_combat() -> void:
	set_state(ControllerState.COMBAT)


func exit_combat() -> void:
	if _turn_manager.get_active_actor() == _player:
		set_state(ControllerState.MOVEMENT)
	else:
		set_state(ControllerState.IDLE)


func on_setup_biome_selected(biome_data: BiomeData) -> void:
	_setup_selected_biome = biome_data


func on_setup_biome_placed() -> void:
	_setup_selected_biome = null


func on_all_setup_biomes_placed() -> void:
	_is_placing_command_tower = true


func on_command_tower_placed() -> void:
	_is_placing_command_tower = false
#endregion


#region Accessors
func get_state() -> ControllerState:
	return _state


func set_state(value: ControllerState) -> void:
	_state = value


func is_active_player() -> bool:
	return _is_active_player


func set_is_active_player(value: bool) -> void:
	_is_active_player = value
#endregion


#region Input states
func _input_idle(event: InputEvent) -> void:
	if event.is_action_released("right_click"):
		_view_lander_under_mouse()


func _input_collapsing_dustcloud(event: InputEvent) -> void:
	if event.is_action_released("left_click"):
		var hit := _raycast_to_layer(WORLD_SURFACE_LAYER)
		if hit:
			var action := Action.create(Action.Type.PLACE_LANDER)
			action.set_position(hit.position)
			action_requested.emit(action)
	elif event.is_action_released("right_click"):
		_view_lander_under_mouse()


func _input_movement(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		_is_dragging = true
		var hit := _raycast_to_layer(LANDER_LAYER)
		if hit:
			_drag_start_lander = hit.collider
			if _drag_start_lander.get_owner_actor() == _player:
				_drag_connected_landers = _lander_manager.get_connected_landers(_drag_start_lander)
			else:
				_drag_connected_landers = []

	elif event.is_action_released("left_click"):
		_finish_drag()

	elif event.is_action_released("right_click"):
		_view_lander_under_mouse()


func _input_setup(event: InputEvent) -> void:
	if not event.is_action_pressed("left_click"):
		return
	if _is_placing_command_tower:
		_try_place_command_tower()
	else:
		_try_place_setup_biome()
#endregion


#region Process states
func _process_collapsing_dustcloud(delta: float) -> void:
	_dustcloud_preview_timer += delta
	if _dustcloud_preview_timer < DUSTCLOUD_PREVIEW_INTERVAL:
		return
	_dustcloud_preview_timer = 0

	var hit := _raycast_to_layer(WORLD_SURFACE_LAYER)
	if not hit.has("position"):
		return
	var mouse_position: Vector3 = hit["position"]

	var color := Color.WEB_GREEN                       # free space
	if not _lander_manager.is_position_clear(mouse_position):
		color = Color.RED                              # overlapping a lander
	elif _lander_manager.is_position_adjacent(mouse_position):
		color = Color.REBECCA_PURPLE                   # next to a lander
	_draw_3d.circle(mouse_position, LanderManager.LANDER_RADIUS, color, DUSTCLOUD_PREVIEW_INTERVAL)


func _process_movement(delta: float) -> void:
	if not _is_dragging or _drag_start_lander == null:
		return
	_movement_preview_timer += delta
	if _movement_preview_timer < MOVEMENT_PREVIEW_INTERVAL:
		return
	_movement_preview_timer = 0
	if _drag_start_lander.get_owner_actor() != _player:
		return

	var hit := _raycast_to_layer(LANDER_LAYER)
	_drag_end_lander = hit.collider if hit else null

	var start := _drag_start_lander.global_transform.origin + Vector3.UP
	if _drag_end_lander != null and _drag_end_lander in _drag_connected_landers:
		var end := _drag_end_lander.global_transform.origin + Vector3.UP
		var end_owner := _drag_end_lander.get_owner_actor()
		var color := Color.RED                         # enemy
		if end_owner == null:
			color = Color.GOLD                         # unoccupied
		elif end_owner == _player:
			color = Color.MAGENTA                      # own both
		_draw_3d.line(start, end, color, MOVEMENT_PREVIEW_INTERVAL)
	else:
		var surface_hit := _raycast_to_layer(WORLD_SURFACE_LAYER)
		if surface_hit:
			_draw_3d.line(start, surface_hit.position, Color.LIGHT_BLUE, MOVEMENT_PREVIEW_INTERVAL)
#endregion


#region Private
func _finish_drag() -> void:
	var start := _drag_start_lander
	var end := _drag_end_lander
	_is_dragging = false
	_drag_start_lander = null
	_drag_end_lander = null

	if start == null or end == null:
		return
	if start.get_owner_actor() != _player or end not in _lander_manager.get_connected_landers(start):
		return

	var end_owner := end.get_owner_actor()
	if end_owner == null or end_owner == _player:
		movement_ui_requested.emit(start, end)  # Neutral or allied: pick units to move
	else:
		var action := Action.create(Action.Type.ATTACK)
		action.set_source_lander(start)
		action.set_target_lander(end)
		action_requested.emit(action)


func _try_place_setup_biome() -> void:
	if _setup_selected_biome == null:
		print("PlayerController | No biome selected for setup placement")
		return
	var surface_hit := _raycast_to_layer(WORLD_SURFACE_LAYER)
	var lander_hit := _raycast_to_layer(LANDER_LAYER)
	if surface_hit.is_empty() or not lander_hit.is_empty():
		print("PlayerController | Invalid lander placement during setup")
		return
	var action := Action.create(Action.Type.PLACE_BIOME)
	action.set_position(surface_hit["position"])
	action.set_biome_data(_setup_selected_biome)
	action_requested.emit(action)


func _try_place_command_tower() -> void:
	var lander_hit := _raycast_to_layer(LANDER_LAYER)
	if lander_hit.is_empty():
		return
	var lander: Lander = lander_hit["collider"]
	if lander.get_owner_actor() != null:
		print("PlayerController | The command tower can not be placed on an occupied lander")
		return
	var action := Action.create(Action.Type.PLACE_BUILDING)
	action.set_target_lander(lander)
	action.set_building_data(_player.get_species().get_command_tower())
	action_requested.emit(action)


func _view_lander_under_mouse() -> void:
	var hit := _raycast_to_layer(LANDER_LAYER)
	if hit:
		lander_selected.emit(hit.collider)
		lander_view_requested.emit(hit.collider)


func _raycast_to_layer(layer: int) -> Dictionary:
	var mouse_position := get_viewport().get_mouse_position()
	var ray_start := _camera.project_ray_origin(mouse_position)
	var ray_end := ray_start + _camera.project_ray_normal(mouse_position) * RAYCAST_LENGTH
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, layer)
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_ray(query)
#endregion
