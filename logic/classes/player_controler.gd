class_name PlayerControler
extends ActorControler

### signals
signal select_lander(target_lander)
signal view_lander_requested(target_lander)
signal attack_action_req(action_req)
signal run_movement_ui(from:Lander, to:Lander)

# enums
enum PlayerState {
	IDLE,
	COLLASPING_DUSTCLOUD,
	BUYING,
	MOVEMENT,
	COMBAT,
	DEAD,
	SETUP,
}


### constants
const RAYCAST_WORLD_SURFACE_LENGHT = 100
const WORLD_SURFACE_LAYER: int = 1
const LANDER_LAYER: int = 2


### 
#static variables
var selector_manager: GameManager
var turn_manager: GameManager
var lander_manager: GameManager
var draw_3d: Draw3D
var self_player: Player

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
var is_in_setup: bool = false:
	set(value):
		if(value): player_state = PlayerState.SETUP

# Input state controls
var i_movement_ldown: bool = false

# Process state controls
var p_movement_timer: float = 0
var p_movement_update_rate: float = 1.0/30.0 #update = 30FPS
var p_dc_timer: float = 0
var p_dc_update_rate: float = 1.0/60.0 #update = 60FPS

## State controls
# Movement
var m_start_lander: Lander
var m_end_lander: Lander
var _mouse_line
var m_connected_landers: Array[Lander]
# Dusctcloud Collaspe
var _dc_mouse_lander


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
		PlayerState.COLLASPING_DUSTCLOUD:
			process_state_dustcloud_collaspe(delta)
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
		if m_start_lander != null and m_end_lander != null and m_start_lander.get_ownr() == self_player :
			# If neutral init movement UI
			if m_end_lander.get_ownr() == null:
				run_movement_ui.emit(m_start_lander, m_end_lander)
				print("Player Controller | Emit | Run movement UI emitted")
			# If Attack send out attack req
			elif m_end_lander.get_ownr() != self_player:
				var action_req = Action.new()
				action_req.set_type(Action.RequestType.ATTACK)
				action_req.set_selected_lander(m_start_lander)
				action_req.set_target_lander(m_end_lander)
				attack_action_req.emit(action_req)
			# If Ally init movement UI
			elif m_end_lander.get_ownr() == self_player:
				run_movement_ui.emit(m_start_lander, m_end_lander)
				print("Player Controller | Emit | Run movement UI emitted")

		# Reset movement state		
		i_movement_ldown = false
		m_start_lander = null
		m_end_lander = null


	elif event.is_action_pressed("left_click"):
		i_movement_ldown = true
		
		var raycast_hit = raycat_to_layer(LANDER_LAYER)
		if raycast_hit:
			m_start_lander = raycast_hit.collider

			if m_start_lander.get_ownr() == self_player:
				m_connected_landers = lander_manager.get_connected_landers(m_start_lander)
			else:
				m_connected_landers = []
				

	#Right Click down/up
	elif event.is_action_released("right_click"):
		view_lander_event()


### Process States
func process_state_idle(delta: float) -> void:
	pass


func process_state_dustcloud_collaspe(delta: float):
	p_dc_timer += delta
	if p_dc_timer >= p_dc_update_rate:
		p_dc_timer = 0
		
		var world_raycast_hit = raycat_to_layer(WORLD_SURFACE_LAYER)
		if world_raycast_hit and world_raycast_hit.has("position"):
			var mouse_pos = world_raycast_hit["position"]
			# If mouse_pos overlapping lander: Red
			if lander_manager.is_pos_min_distance_apart(mouse_pos) == false:
				# make red
				_dc_mouse_lander = await draw_3d.circle(mouse_pos, lander_manager.LANDER_RADIUS,
				Color.RED, p_dc_update_rate)
				pass
			# If mouse_pos next to lander: Purple
			elif lander_manager.is_pos_lander_adjacent(mouse_pos):
				# make purple
				_dc_mouse_lander = await draw_3d.circle(mouse_pos, lander_manager.LANDER_RADIUS,
				Color.REBECCA_PURPLE, p_dc_update_rate)
			# If not overlapping or next to a lander: Green
			else:
				# make green
				_dc_mouse_lander = await draw_3d.circle(mouse_pos, lander_manager.LANDER_RADIUS,
				Color.WEB_GREEN, p_dc_update_rate)


func process_state_movement(delta: float) -> void:
	if i_movement_ldown and m_start_lander != null:
		p_movement_timer += delta
		if p_movement_timer >= p_movement_update_rate:
			p_movement_timer = 0
			if m_start_lander.get_ownr() == self_player: # If moving from owned lander
				var lander_raycast_hit = raycat_to_layer(LANDER_LAYER)
				if lander_raycast_hit:
					m_end_lander = lander_raycast_hit.collider
				else:
					m_end_lander = null

				if m_end_lander != null and m_end_lander in m_connected_landers:
					if m_end_lander.get_ownr() == null: # If unoccupied: line = yellow
						_mouse_line = await draw_3d.line(m_start_lander.global_transform.origin + Vector3.UP, 
						m_end_lander.global_transform.origin + Vector3.UP, Color.GOLD, p_movement_update_rate)
					elif m_end_lander.get_ownr() == self_player: # If own both: line = purple
						_mouse_line = await draw_3d.line(m_start_lander.global_transform.origin + Vector3.UP, 
						m_end_lander.global_transform.origin + Vector3.UP, Color.MAGENTA, p_movement_update_rate)
					elif m_end_lander.get_ownr() != self_player: #If owned by enemy: Line = red
						_mouse_line = await draw_3d.line(m_start_lander.global_transform.origin + Vector3.UP, 
						m_end_lander.global_transform.origin + Vector3.UP, Color.RED, p_movement_update_rate)
					else: # Errror case: line = Green
						_mouse_line = await draw_3d.line(m_start_lander.global_transform.origin + Vector3.UP, 
						m_end_lander.global_transform.origin + Vector3.UP, Color.SEA_GREEN, p_movement_update_rate)
				else:
					var surface_raycast_hit = raycat_to_layer(WORLD_SURFACE_LAYER)
					if surface_raycast_hit:
						var mouse_pos_V3:Vector3 = surface_raycast_hit.position
						_mouse_line = await draw_3d.line(m_start_lander.global_transform.origin + Vector3.UP, 
						mouse_pos_V3, Color.LIGHT_BLUE, p_movement_update_rate)
			else:
				pass
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
func bind_player(p: Player):
	self_player = p


func bind_lander_manager(lm: GameManager):
	lander_manager = lm


func actor_turn_changed(active_actor: Actor):
	is_active_player = true if active_actor == self_player else false
	print("Player | Update | Active self_player changed to: " + active_actor.name)


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
	#print("Player | Update | Player state changed to: " + str(PlayerState.keys()[player_state]))


func game_state_changed(game_state):
	if not is_active_player:
		player_state = PlayerState.IDLE
		return
	else:
		if game_state == turn_manager.GameSequence.SETUP:
			is_in_setup = true
			print("Player Controller | Debug | Entering Game Setup")
			return
		else: is_in_setup = false


### Action templates
func generate_place_lander_request(pos: Vector3):
	var action_req = Action.new()
	action_req.set_actor(self_player)
	action_req.set_pos(pos)
	action_req.set_type(Action.RequestType.PLACE_LANDER)
	action_manager.action_request(action_req)

# Calls
func enter_combat():
	player_state = PlayerState.COMBAT


func exit_combat():
	if turn_manager.get_active_actor() == self_player:
		player_state = PlayerState.MOVEMENT
	else:
		player_state = PlayerState.IDLE

func set_is_active_player(b: bool):
	is_active_player = b
	

### Wires and Signals
func bind_selector(selector: GameManager):
	selector_manager = selector

func bind_turn_manager(tm: GameManager):
	turn_manager = tm
