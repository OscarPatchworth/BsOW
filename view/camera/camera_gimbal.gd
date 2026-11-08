# camera_gimbal.gd
# Based on: https://kidscancode.org/godot_recipes/4.x/3d/camera_gimbal/index.html
class_name CameraGimbal
extends Node3D

## Orbit camera rig. Expects this layout:
##   CameraGimbal (yaw)
##   └─ InnerGimbal (pitch)
##      └─ Camera3D
##
## Controls:  cam_left/cam_right = yaw,  cam_up/cam_down = pitch,
##            cam_zoom_in/cam_zoom_out = zoom,  hold middle mouse + drag = orbit.

## Optional node to follow.
@export var target: Node3D

@export_group("Rotation")
@export_range(0.0, 4.0) var rotation_speed: float = PI / 2
@export_range(0.001, 0.05) var mouse_sensitivity: float = 0.005
@export var invert_x: bool = false
@export var invert_y: bool = false
## Pitch limits in radians (negative looks down).
@export var min_pitch: float = -1.4
@export var max_pitch: float = -0.01

@export_group("Zoom")
@export var min_zoom: float = 0.4
@export var max_zoom: float = 3.0
## How much one scroll step changes the zoom.
@export_range(0.05, 1.0) var zoom_speed: float = 0.09
## How quickly the rig eases toward the target zoom (higher = snappier).
@export_range(1.0, 30.0) var zoom_smoothing: float = 8.0

var _zoom: float = 1.5
var _is_orbiting: bool = false

@onready var _inner_gimbal: Node3D = $InnerGimbal


func _ready() -> void:
	_zoom = clampf(_zoom, min_zoom, max_zoom)


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
	_rotate_yaw(Input.get_axis("cam_left", "cam_right") * rotation_speed * delta)
	var pitch_input := Input.get_axis("cam_up", "cam_down")
	_rotate_pitch((-pitch_input if invert_y else pitch_input) * rotation_speed * delta)

	# Frame-rate independent easing toward the target zoom.
	var weight := 1.0 - exp(-zoom_smoothing * delta)
	scale = scale.lerp(Vector3.ONE * _zoom, weight)

	if target:
		global_position = target.global_position


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
#endregion
