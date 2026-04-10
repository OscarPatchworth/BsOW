class_name PlayerControler
extends ActorControler

### signals
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


### constants
const RAYCAST_WORLD_SURFACE_LENGHT = 100
const WORLD_SURFACE_LAYER: int = 1
const LANDER_LAYER: int = 2


### 
#static variables
var selector_manager: GameManager
var turn_manager: GameManager
var draw_3d: Draw3D

### 
#@export variables


### 
#remaining regular variables
var mouse = Vector2()
#Get cam and world space init
var space_state
var mouse_pos 

#Get raycast points
var mouse_ray_start 
var mouse_ray_end

# Player state controls
var is_active_player: bool = false
var player_state:PlayerState = PlayerState.IDLE

# Input state controls
var i_movement_ldown: bool = false

# Process state controls
var p_movement_timer: float = 0
var p_movement_update_rate: float = 1.0/30.0 #update = 30FPS

## State controls
# Movement
var m_start_lander: Lander
var m_end_lander: Lander
var _mouse_line


### @onready variables
@onready var cam: Camera3D = self.find_child("Camera3D")

###################################################################################################
###	Methods
# Called Whenever there is user input
func _input(event: InputEvent) -> void: 
	match player_state:
		PlayerState.IDLE:
			input_state_idle(event)
		PlayerState.COLLASPING_DUSTCLOUD:
			input_state_collapsing_dustcloud(event)
		PlayerState.MOVEMENT:
			input_state_movement(event)
		_:
			input_state_idle(event)


func _process(delta: float) -> void:
	match player_state:
		PlayerState.IDLE:
			process_state_idle(delta)
		PlayerState.MOVEMENT:
			process_state_movement(delta)
		_:
			process_state_idle(delta)



###########################################################################################################
# Player States:

### Input States
func input_state_idle(event: InputEvent) -> void:
	if event.is_action_released("right_click"):
		view_lander_event()


func input_state_collapsing_dustcloud(event: InputEvent) -> void:
	if event.is_action_released("left_click"):
		place_lander_event()
	elif event.is_action_released("right_click"):
		view_lander_event()


func input_state_movement(event):
	# Left Click down/up
	if event.is_action_released("left_click"):
		i_movement_ldown = false
		m_start_lander = null
		m_end_lander = null
	elif event.is_action_pressed("left_click"):
		i_movement_ldown = true
		
		var raycast_hit = raycat_to_layer(LANDER_LAYER)
		if raycast_hit:
			m_start_lander = raycast_hit.collider

	#Right Click down/up
	elif event.is_action_released("right_click"):
		view_lander_event()


### Process States
func process_state_idle(delta: float) -> void:
	pass


func process_state_movement(delta: float) -> void:
	if i_movement_ldown and m_start_lander != null:
		p_movement_timer += delta
		if p_movement_timer >= p_movement_update_rate:
			p_movement_timer = 0

			var lander_raycast_hit = raycat_to_layer(LANDER_LAYER)
			if lander_raycast_hit:
				m_end_lander = lander_raycast_hit.collider
			else:
				m_end_lander = null

			if m_end_lander != null:
				_mouse_line = await draw_3d.line(m_start_lander.global_transform.origin + Vector3.UP, 
				m_end_lander.global_transform.origin + Vector3.UP, Color.RED, p_movement_update_rate)
			else:
				var surface_raycast_hit = raycat_to_layer(WORLD_SURFACE_LAYER)
				if surface_raycast_hit:
					var mouse_pos_V3:Vector3 = surface_raycast_hit.position
					_mouse_line = await draw_3d.line(m_start_lander.global_transform.origin + Vector3.UP, 
					mouse_pos_V3, Color.LIGHT_BLUE, p_movement_update_rate)
		else:
			pass


### Methods
func place_lander_event():
	var raycast_hit = raycat_to_layer(WORLD_SURFACE_LAYER)
	if raycast_hit:
		generate_place_lander_request(raycast_hit.position)

func view_lander_event():
	var raycast_hit = raycat_to_layer(LANDER_LAYER)
	if raycast_hit:
		select_lander.emit(raycast_hit.collider)
		view_lander_requested.emit(raycast_hit.collider)


## 2ndary Methods
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


#Returns the position in 3d that the mouse is hovering, or null if it isnt hovering anything
func get_mouse_pos():
	var space_state = get_parent().get_world_3d().get_direct_space_state()
	var mouse_position = get_viewport().get_mouse_position()
	var camera = get_tree().root.get_camera_3d()
	
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_position) * 1000
		
	var params = PhysicsRayQueryParameters3D.new()
	params.from = ray_origin
	params.to = ray_end
	params.collision_mask = LANDER_LAYER
	params.exclude = []
	
	var rayDic = space_state.intersect_ray(params)	
	
	if rayDic.has("position"):
		return rayDic["position"]
	return null



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
