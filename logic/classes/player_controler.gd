class_name PlayerControler
extends ActorControler

# signals

# enums

# constants
const RAYCAST_WORLD_SURFACE_LENGHT = 100

# static variables
var cam: Camera3D

# @export variables

# remaining regular variables
var mouse = Vector2()
#Get cam and world space init
var space_state
var mouse_pos 
#Get raycast points
var mouse_ray_start 
var mouse_ray_end

# @onready variables


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# Called Whenever there is user input
func _input(event: InputEvent) -> void: 
	if event.is_action_released("left_click"):
		var raycast_hit = raycat_to_world_surface()
		if raycast_hit:
			var action_req = Action.new()
			action_req.set_actor(self.get_parent())
			action_req.set_pos(raycast_hit.position)
			action_req.set_type(Action.RequestType.PLACE_LANDER)
			action_manager.action_request(action_req)
	pass


func raycat_to_world_surface() -> Dictionary:
	#Get cam and world space init
	init_raycast_mouse_pos()
	#Raycast layer 1 (the world surface layer)
	var query = PhysicsRayQueryParameters3D.create(mouse_ray_start, mouse_ray_end, 1)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	return result


func init_raycast_mouse_pos() -> void:
	#Get cam and world space init
	space_state = get_world_3d().direct_space_state
	mouse_pos = get_viewport().get_mouse_position()
	#Get raycast points
	mouse_ray_start = cam.project_ray_origin(mouse_pos)
	mouse_ray_end = mouse_ray_start + cam.project_ray_normal(mouse_pos) * RAYCAST_WORLD_SURFACE_LENGHT
