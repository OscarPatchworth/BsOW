# camera_gimbal.gd
# Based on: https://kidscancode.org/godot_recipes/4.x/3d/camera_gimbal/index.html
class_name CameraGimbal
extends Node3D

## Orbit camera rig. Expects this layout:
##   CameraGimbal (yaw, position on the board)
##   └─ InnerGimbal (pitch)
##      └─ Camera3D
##
## Controls:  WASD = pan across the board,  Q/E = rotate,
##            mouse wheel = zoom,  hold middle mouse + drag = orbit.
## focus_on(point) glides the rig to look at a point on the board.

const ROTATE_LEFT_ACTION := &"cam_rotate_left"
const ROTATE_RIGHT_ACTION := &"cam_rotate_right"

## Optional node to follow.
@export var target: Node3D

@export_group("Rotation")
@export_range(0.0, 4.0) var rotation_speed: float = PI / 2
@export_range(0.001, 0.05) var mouse_sensitivity: float = 0.005
@export var invert_x: bool = false
@export var invert_y: bool = false
## Pitch limits in radians (negative looks down).
@export var min_pitch: float = -1.4
@export var max_pitch: float = -0.25
@export var start_pitch: float = -0.75

@export_group("Pan")
## Board units per second at zoom 1 (panning is faster when zoomed out).
@export var pan_speed: float = 6.0
## Keeps the camera over the play area.
@export var pan_limit: float = 22.0
## How quickly the rig eases toward its target position (higher = snappier).
@export_range(1.0, 30.0) var pan_smoothing: float = 10.0

@export_group("Zoom")
@export var min_zoom: float = 0.4
@export var max_zoom: float = 3.0
@export var start_zoom: float = 3.2
## How much one scroll step changes the zoom.
@export_range(0.05, 1.0) var zoom_speed: float = 0.09
## How quickly the rig eases toward the target zoom (higher = snappier).
@export_range(1.0, 30.0) var zoom_smoothing: float = 8.0

var _zoom: float = 1.5
var _target_position: Vector3
var _is_orbiting: bool = false

@onready var _inner_gimbal: Node3D = $InnerGimbal


func _ready() -> void:
	_register_rotate_actions()
	_zoom = clampf(start_zoom, min_zoom, max_zoom)
	scale = Vector3.ONE * _zoom
	_inner_gimbal.rotation.x = clampf(start_pitch, min_pitch, max_pitch)
	global_position.y = 0
	_target_position = global_position


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cam_zoom_in"):
		_zoom -= zoom_speed
	elif event.is_action_pressed("cam_zoom_out"):
		_zoom += zoom_speed
	_zoom = clampf(_zoom, min_zoom, max_zoom)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_is_orbiting = event.pressed
	elif event is InputEventMouseMotion and _is_orbiting:
		_rotate_yaw(-event.relative.x * mouse_sensitivity * (-1.0 if invert_x else 1.0))
		_rotate_pitch(-event.relative.y * mouse_sensitivity * (-1.0 if invert_y else 1.0))


func _process(delta: float) -> void:
	_rotate_yaw(Input.get_axis(ROTATE_RIGHT_ACTION, ROTATE_LEFT_ACTION) * rotation_speed * delta)

	var pan_input := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	if pan_input != Vector2.ZERO:
		# Pan relative to where the camera faces, flat on the board.
		var right := global_basis.x
		var forward := global_basis.z
		right.y = 0
		forward.y = 0
		var direction := right.normalized() * pan_input.x + forward.normalized() * pan_input.y
		_target_position += direction * pan_speed * _zoom * delta
	if target:
		_target_position = target.global_position
	_target_position.x = clampf(_target_position.x, -pan_limit, pan_limit)
	_target_position.z = clampf(_target_position.z, -pan_limit, pan_limit)
	_target_position.y = 0

	# Frame-rate independent easing toward the target position and zoom.
	global_position = global_position.lerp(_target_position, 1.0 - exp(-pan_smoothing * delta))
	scale = scale.lerp(Vector3.ONE * _zoom, 1.0 - exp(-zoom_smoothing * delta))


#region Public API
## Glides the camera to look at `point` on the board.
func focus_on(point: Vector3) -> void:
	_target_position = Vector3(point.x, 0, point.z)
#endregion


#region Accessors
func get_zoom() -> float:
	return _zoom


func set_zoom(value: float) -> void:
	_zoom = clampf(value, min_zoom, max_zoom)
#endregion


#region Private
func _rotate_yaw(amount: float) -> void:
	rotate_object_local(Vector3.UP, amount)


func _rotate_pitch(amount: float) -> void:
	_inner_gimbal.rotate_object_local(Vector3.RIGHT, amount)
	_inner_gimbal.rotation.x = clampf(_inner_gimbal.rotation.x, min_pitch, max_pitch)


## Q/E aren't in project.godot's input map, so add them here if they're missing.
func _register_rotate_actions() -> void:
	for pair: Array in [[ROTATE_LEFT_ACTION, KEY_Q], [ROTATE_RIGHT_ACTION, KEY_E]]:
		if InputMap.has_action(pair[0]):
			continue
		InputMap.add_action(pair[0])
		var key := InputEventKey.new()
		key.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], key)
#endregion
