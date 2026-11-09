# player_controller.gd
class_name PlayerController
extends Node3D

## Turns mouse input in the 3D world into selections and Actions for the local Player, and
## draws the world-space hints for them (PlacementPreview).
##
##   Left click a lander        select it (the HUD shows it)
##   Right click a lander       select it too
##   Dustcloud / setup          the ghost follows the cursor and shows where gravity pulls it;
##                              left click places
##   Combat phase               drag from your lander to a connected one: move units, attack,
##                              or move onto an undefended enemy lander (capture or raze)
##
## Uses _unhandled_input, so clicks on HUD controls never reach the board.

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

const RAYCAST_LENGTH: float = 200.0
const WORLD_SURFACE_LAYER: int = 1
const LANDER_LAYER: int = 2
## How often the gravity prediction is recalculated while the cursor moves.
const PLACEMENT_PREVIEW_INTERVAL: float = 1.0 / 30.0
## Moving the mouse less than this (pixels) between press and release counts as a click.
const CLICK_SLOP: float = 8.0

const DRAG_MOVE_COLOR := Color(1.0, 0.85, 0.3, 0.9)
const DRAG_ATTACK_COLOR := Color(1.0, 0.3, 0.3, 0.9)
const DRAG_TAKE_COLOR := Color(1.0, 0.6, 0.2, 0.9)
const DRAG_INVALID_COLOR := Color(0.7, 0.7, 0.7, 0.5)

var _player: Player
var _selector_manager: SelectorManager
var _turn_manager: TurnManager
var _lander_manager: LanderManager
var _gravity_system: GravitySystem

var _state: ControllerState = ControllerState.IDLE
var _is_active_player: bool = false

var _pressed_lander: Lander
var _press_position: Vector2
var _is_dragging: bool = false
var _hovered_lander: Lander
var _placement_timer: float = 0.0

# Setup state
var _setup_selected_biome: BiomeData
var _is_placing_command_tower: bool = false

@onready var _camera: Camera3D = find_child("Camera3D")
@onready var _gimbal: CameraGimbal = find_child("CamGimbal")
var _preview: PlacementPreview


func _ready() -> void:
	_preview = PlacementPreview.new()
	_preview.name = "PlacementPreview"
	add_child(_preview)
	if _lander_manager != null:
		_preview.set_connection_distance(_lander_manager.get_connected_lander_distance())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		_press_position = get_viewport().get_mouse_position()
		_pressed_lander = _lander_under_mouse()
		_is_dragging = _state == ControllerState.MOVEMENT and _pressed_lander != null \
			and _pressed_lander.get_owner_actor() == _player
	elif event.is_action_released("left_click"):
		_on_left_click_released()
	elif event.is_action_released("right_click"):
		_select(_lander_under_mouse())


func _process(delta: float) -> void:
	_hovered_lander = _lander_under_mouse()
	match _state:
		ControllerState.COLLAPSING_DUSTCLOUD:
			var next_biome := _lander_manager.peek_next_biome(_player)
			_update_placement_preview(delta, HudTheme.biome_color(next_biome), _biome_caption(next_biome))
		ControllerState.SETUP:
			_update_setup_preview(delta)
		ControllerState.MOVEMENT:
			_update_drag_preview()
		_:
			_preview.hide_placement()
	if _state != ControllerState.SETUP or not _is_placing_command_tower:
		_preview.show_hover(_hovered_lander)


#region Public API
func bind_player(player: Player) -> void:
	_player = player


func bind_selector_manager(selector_manager: SelectorManager) -> void:
	_selector_manager = selector_manager


func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager


func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_manager = lander_manager
	if _preview != null:
		_preview.set_connection_distance(lander_manager.get_connected_lander_distance())


func bind_gravity_system(gravity_system: GravitySystem) -> void:
	_gravity_system = gravity_system


## Glides the camera to look at a point on the board.
func focus_camera_on(point: Vector3) -> void:
	_gimbal.focus_on(point)


func apply_active_actor(active_actor: Actor) -> void:
	set_is_active_player(active_actor == _player)


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
	elif state == TurnManager.GameState.END:
		set_state(ControllerState.IDLE)  # You can still look around and select landers.


func enter_combat() -> void:
	set_state(ControllerState.COMBAT)


func exit_combat() -> void:
	if _turn_manager.get_active_actor() == _player and _turn_manager.get_game_phase() == TurnManager.Phase.COMBAT:
		set_state(ControllerState.MOVEMENT)
	elif _turn_manager.get_active_actor() != _player:
		set_state(ControllerState.IDLE)


func on_setup_biome_selected(biome_data: BiomeData) -> void:
	_setup_selected_biome = biome_data


func on_setup_biome_placed() -> void:
	_setup_selected_biome = null


func on_all_setup_biomes_placed() -> void:
	_is_placing_command_tower = true


func on_command_tower_placed() -> void:
	_is_placing_command_tower = false


func is_placing_command_tower() -> bool:
	return _is_placing_command_tower


func get_setup_selected_biome() -> BiomeData:
	return _setup_selected_biome
#endregion


#region Accessors
func get_state() -> ControllerState:
	return _state


func set_state(value: ControllerState) -> void:
	_state = value
	_is_dragging = false
	_preview.hide_placement()


func is_active_player() -> bool:
	return _is_active_player


func set_is_active_player(value: bool) -> void:
	_is_active_player = value
#endregion


#region Clicks
func _on_left_click_released() -> void:
	var released_lander := _lander_under_mouse()
	var was_click := get_viewport().get_mouse_position().distance_to(_press_position) < CLICK_SLOP
	var was_dragging := _is_dragging
	_is_dragging = false

	match _state:
		ControllerState.COLLAPSING_DUSTCLOUD:
			if released_lander != null:
				_select(released_lander)
			elif was_click:
				_request_place(Action.Type.PLACE_LANDER, null)
		ControllerState.SETUP:
			if _is_placing_command_tower:
				_try_place_command_tower(released_lander)
			elif released_lander != null:
				_select(released_lander)
			elif was_click and _setup_selected_biome != null:
				_request_place(Action.Type.PLACE_BIOME, _setup_selected_biome)
		ControllerState.MOVEMENT:
			if was_dragging and released_lander != null and released_lander != _pressed_lander:
				_finish_drag(_pressed_lander, released_lander)
			elif released_lander != null:
				_select(released_lander)
		_:
			if released_lander != null:
				_select(released_lander)
	_pressed_lander = null
	_preview.hide_placement()


func _select(lander: Lander) -> void:
	if lander == null:
		return
	lander_selected.emit(lander)
	lander_view_requested.emit(lander)


func _request_place(type: Action.Type, biome_data: BiomeData) -> void:
	var spot: Variant = _board_point_under_mouse()
	if spot == null:
		return
	var action := Action.create(type)
	action.set_position(spot)
	if biome_data != null:
		action.set_biome_data(biome_data)
	action_requested.emit(action)


func _try_place_command_tower(lander: Lander) -> void:
	if lander == null:
		return
	var action := Action.create(Action.Type.PLACE_BUILDING)
	action.set_target_lander(lander)
	action.set_building_data(_player.get_species().get_command_tower())
	action_requested.emit(action)


func _finish_drag(start: Lander, end: Lander) -> void:
	if start == null or start.get_owner_actor() != _player:
		return
	if not _lander_manager.are_connected(start, end):
		_select(end)
		return
	var end_owner := end.get_owner_actor()
	if end_owner != null and end_owner != _player and end.has_units():
		var action := Action.create(Action.Type.ATTACK)
		action.set_source_lander(start)
		action.set_target_lander(end)
		action_requested.emit(action)
	else:
		# Neutral, ours, or an undefended enemy lander: choose units (and capture/raze) in the HUD.
		movement_ui_requested.emit(start, end)
#endregion


#region Previews
## "Mountain\n+1 mineral, +1 stone per turn"
static func _biome_caption(biome: BiomeData) -> String:
	return "%s\n%s per turn" % [biome.get_display_name(), HudTheme.format_yield(biome.get_upkeep())]


func _update_placement_preview(delta: float, tint: Color, caption: String = "") -> void:
	_placement_timer -= delta
	if _placement_timer > 0.0:
		return
	_placement_timer = PLACEMENT_PREVIEW_INTERVAL
	var spot: Variant = _board_point_under_mouse()
	if spot == null or _hovered_lander != null:
		_preview.hide_placement()
		return
	var problem := _lander_manager.get_placement_problem(spot)
	var is_valid := problem == ""
	var settle_spot: Vector3 = _gravity_system.predict_settle_position(spot) if is_valid else spot
	var connects := _lander_manager.get_landers_within(settle_spot, _lander_manager.get_connected_lander_distance())
	var pulls: Dictionary = _gravity_system.get_pull_preview(spot) if is_valid else {}
	_preview.show_placement(spot, is_valid, settle_spot, pulls, connects, tint, caption, problem)


func _update_setup_preview(delta: float) -> void:
	if _is_placing_command_tower:
		_preview.hide_placement()
		var can_take := (_hovered_lander != null and not _hovered_lander.has_building()
			and _hovered_lander in _lander_manager.get_setup_landers_of(_player))
		_preview.show_hover(_hovered_lander, PlacementPreview.VALID_COLOR if can_take else PlacementPreview.INVALID_COLOR)
	elif _setup_selected_biome != null:
		_update_placement_preview(delta, HudTheme.biome_color(_setup_selected_biome), _biome_caption(_setup_selected_biome))
	else:
		_preview.hide_placement()


func _update_drag_preview() -> void:
	if not _is_dragging or _pressed_lander == null:
		_preview.hide_placement()
		return
	var start := _pressed_lander.get_board_position()
	var target := _hovered_lander
	if target != null and target != _pressed_lander:
		var color := DRAG_INVALID_COLOR
		if _lander_manager.are_connected(_pressed_lander, target):
			var target_owner := target.get_owner_actor()
			if target_owner == null or target_owner == _player:
				color = DRAG_MOVE_COLOR
			elif target.has_units():
				color = DRAG_ATTACK_COLOR
			else:
				color = DRAG_TAKE_COLOR
		_preview.show_drag(start, target.get_board_position(), color)
	else:
		var point: Variant = _board_point_under_mouse()
		if point != null:
			_preview.show_drag(start, point, DRAG_INVALID_COLOR)
#endregion


#region Raycasts
func _lander_under_mouse() -> Lander:
	var hit := _raycast_to_layer(LANDER_LAYER)
	return hit.get("collider") as Lander if not hit.is_empty() else null


## The point on the floor under the mouse, or null.
func _board_point_under_mouse() -> Variant:
	var hit := _raycast_to_layer(WORLD_SURFACE_LAYER)
	if hit.is_empty():
		return null
	var point: Vector3 = hit["position"]
	return Vector3(point.x, 0, point.z)


func _raycast_to_layer(layer: int) -> Dictionary:
	if _camera == null or not is_inside_tree():
		return {}
	var mouse_position := get_viewport().get_mouse_position()
	var ray_start := _camera.project_ray_origin(mouse_position)
	var ray_end := ray_start + _camera.project_ray_normal(mouse_position) * RAYCAST_LENGTH
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, layer)
	query.collide_with_bodies = true
	return get_world_3d().direct_space_state.intersect_ray(query)
#endregion
