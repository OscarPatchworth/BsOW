class_name PlayerControler
extends ActorControler

# signals
signal select_lander(target_lander)
signal view_lander_requested(target_lander)

# enums
enum PlayerState {
	IDLE,
	COLLASPING_DUSTCLOUD,
	BUYING,
	MOVEMENT,
	COMBAT,
	DEAD,
}


# constants
const RAYCAST_WORLD_SURFACE_LENGHT = 100
const WORLD_SURFACE_LAYER: int = 1
const LANDER_LAYER: int = 2

# static variables
var selector_manager: GameManager
var turn_manager: GameManager

# @export variables

# remaining regular variables
var mouse = Vector2()
#Get cam and world space init
var space_state
var mouse_pos 
#Get raycast points
var mouse_ray_start 
var mouse_ray_end

var is_active_player: bool = false
var player_state:PlayerState = PlayerState.IDLE

# @onready variables
@onready var cam: Camera3D = self.find_child("Camera3D")

###################################################################################################
###	Methods
# Called Whenever there is user input
func _input(event: InputEvent) -> void: 
	if event.is_action_released("left_click"):
		var raycast_hit = raycat_to_layer(WORLD_SURFACE_LAYER)
		if raycast_hit:
			generate_place_lander_request(raycast_hit.position)

	elif event.is_action_released("right_click"):
		var raycast_hit = raycat_to_layer(LANDER_LAYER)
		if raycast_hit:
			select_lander.emit(raycast_hit.collider)
			view_lander_requested.emit(raycast_hit.collider)



func raycat_to_layer(layer: int) -> Dictionary:
	#Get cam and world space init
	init_raycast_mouse_pos()
	#Raycast layer 1 (the world surface layer)
	var query = PhysicsRayQueryParameters3D.create(mouse_ray_start, mouse_ray_end, layer)
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


# Calls
func actor_turn_changed(active_actor: Actor):
	is_active_player = true if active_actor == self.get_parent() else false
	print("Player | Update | Active player changed to: " + active_actor.name)

func game_phase_changed(game_phase):
	if not is_active_player:
		player_state = PlayerState.IDLE
		return
	else:
		match game_phase:
			turn_manager.GameLoop.UPKEEP:
				player_state = PlayerState.IDLE
			turn_manager.GameLoop.DUSTCLOUD_COLLASPE_PHASE:
				player_state = PlayerState.COLLASPING_DUSTCLOUD
			turn_manager.GameLoop.BUYING_PHASE:
				player_state = PlayerState.BUYING
			turn_manager.GameLoop.COMBAT_PHASE:
				player_state = PlayerState.MOVEMENT
			turn_manager.GameLoop.CLEANUP:
				player_state = PlayerState.IDLE
	print("Player | Update | Player state changed to: " + str(PlayerState.keys()[player_state]))


### Action templates
func generate_place_lander_request(pos: Vector3):
	var action_req = Action.new()
	action_req.set_actor(self.get_parent())
	action_req.set_pos(pos)
	action_req.set_type(Action.RequestType.PLACE_LANDER)
	action_manager.action_request(action_req)

# Calls
func enter_combat():
	player_state = PlayerState.COMBAT


func exit_combat():
	player_state = PlayerState.IDLE


### Wires and Signals
func bind_selector(selector: GameManager):
	selector_manager = selector

func bind_turn_manager(tm: GameManager):
	turn_manager = tm
