extends Node3D

# signals
signal mouse_moved
signal biome_placed(ply_state : PlayerControlerStateMachine, spawn_spot : Dictionary)
signal update_terrian_info_panel(terrian_info: Dictionary)

# enums
enum PlayerControlerStateMachine {INACTIVE, PLACE_STARTING_TERRIAN, PLACING_TERRIAN}

# constants
const RAY_LENGTH = 100

# static variables
var data_node_ref
var data_store
var game_master
var terrian_info_panel

# export variables
@export var biome_hex: PackedScene
@export var cam: Camera3D
@export var check_terrain_paceable_sence: Node3D

# remaining regular variables
var mouse = Vector2()
#Get cam and world space init
var space_state
var mouse_pos 
#Get raycast points
var mouse_ray_start 
var mouse_ray_end
###
var is_terrian_placeable : bool
var player_state: PlayerControlerStateMachine

# @onready variables
func _ready() -> void:
	data_node_ref = get_node("/root/Node3D/Data/DataNodeRefs")
	data_store = get_node("/" + data_node_ref.DATA_TERRIAN)
	game_master = get_node("/" + data_node_ref.GAME_MASTER)
	terrian_info_panel = get_node(data_node_ref.UI_TERRIAN_INFO)

	player_state = PlayerControlerStateMachine.PLACE_STARTING_TERRIAN
	is_terrian_placeable = false

	ready_signals()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match player_state:
		PlayerControlerStateMachine.INACTIVE:
			pass
		PlayerControlerStateMachine.PLACING_TERRIAN:
			update_placing_terrian()
		PlayerControlerStateMachine.PLACE_STARTING_TERRIAN:
			update_place_starting_terrian()
	

func _input(event: InputEvent) -> void:
	match player_state:
		PlayerControlerStateMachine.INACTIVE:
			pass
		PlayerControlerStateMachine.PLACING_TERRIAN:
			input_placing_terrian(event)
		PlayerControlerStateMachine.PLACE_STARTING_TERRIAN:
			input_place_starting_terrian(event)

###################################################################################################
###	State Machine Funcs

### Switching to states

func switch_state_inactive() -> void:
	check_terrain_paceable_sence.hide()
	player_state = PlayerControlerStateMachine.INACTIVE


func switch_state_placing_terrian() -> void:
	check_terrain_paceable_sence.show()
	player_state = PlayerControlerStateMachine.PLACING_TERRIAN

func switch_state_place_starting_terrian() -> void:
	check_terrain_paceable_sence.show()
	player_state = PlayerControlerStateMachine.PLACE_STARTING_TERRIAN

func switch_state_active() ->void:
	if(game_master.game_state == game_master.GameState.START):
		switch_state_place_starting_terrian()
	elif (game_master.game_state == game_master.GameState.PLACE_TERRIAN):
		switch_state_placing_terrian()
	else:
		switch_state_inactive()


### Update() states

func update_placing_terrian() -> void:
	if check_terrain_paceable_sence:
		move_to_mouse_pos(check_terrain_paceable_sence)

func update_place_starting_terrian() -> void:
	if check_terrain_paceable_sence:
		move_to_mouse_pos(check_terrain_paceable_sence)


### Input() states

func input_placing_terrian(event: InputEvent) -> void:
	if event.is_action_released("left_click") and !raycat_island() and (is_terrian_placeable):
		spawn_terrian()
	elif event.is_action_pressed("shifting") and !raycat_island():
		check_terrain_paceable_sence.show()
	elif event.is_action_released("shifting"):
		check_terrain_paceable_sence.hide()
	elif event.is_action_released("right_click"):
		var raycast_terrian = raycat_island()
		if (raycast_terrian):
			#get terrian data
			var terrian_obj = raycast_terrian["collider"].get_parent()
			var update_terrian_info = {
				"Biome": terrian_obj.current_biome
			}
			#emit data
			update_terrian_info_panel.emit(update_terrian_info)


func input_place_starting_terrian(event: InputEvent) -> void:
	if event.is_action_released("left_click") and !raycat_island() and (is_terrian_placeable):
		spawn_terrian()
	elif event.is_action_pressed("shifting") and !raycat_island():
		check_terrain_paceable_sence.show()
	elif event.is_action_released("shifting"):
		check_terrain_paceable_sence.hide()
	elif event.is_action_released("right_click"):
		var selected_terrian = raycat_island()
		if (selected_terrian):
			update_terrian_info_panel.emit(selected_terrian)



###################################################################################################
###	custom Funcs

func spawn_terrian() -> void:
	var result = raycast_placeable()
	if result and data_store.next_biome != 0: #if hits valid position
		biome_placed.emit(player_state, result)		

		
func raycat_island() -> Dictionary:
	#Get cam and world space init
	init_raycast_mouse_pos()
	#Raycast layer 2 (the island block layer)
	var query = PhysicsRayQueryParameters3D.create(mouse_ray_start, mouse_ray_end, 2)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	return result


func raycast_placeable() -> Dictionary:
	#Get cam and world space init
	init_raycast_mouse_pos()
	#Raycast layer 1 (the placement layer)
	var query = PhysicsRayQueryParameters3D.create(mouse_ray_start, mouse_ray_end, 1)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result	


func init_raycast_mouse_pos() -> void:
	#Get cam and world space init
	space_state = get_world_3d().direct_space_state
	mouse_pos = get_viewport().get_mouse_position()
	#Get raycast points
	mouse_ray_start = cam.project_ray_origin(mouse_pos)
	mouse_ray_end = mouse_ray_start + cam.project_ray_normal(mouse_pos) * RAY_LENGTH


func move_to_mouse_pos(obj: Node3D) -> void:
	var result = raycast_placeable()
	if result and obj: #if hits valid position
		obj.position = result["position"]	
		#obj.position.y = obj.position.y +0.1
	mouse_moved.emit()

func game_master_change_state(state: int) -> void:
	match state:
		2:
			switch_state_placing_terrian()

###################################################################################################
### Connected Signals

func _on_is_placeable_box_is_terrian_placeable(yn: bool) -> void:
	is_terrian_placeable = yn


func _on_starter_terrian_banner_mouse_entered() -> void:
	switch_state_inactive()


func _on_starter_terrian_banner_mouse_exited() -> void:
	if(game_master.game_state == game_master.GameState.START):
		switch_state_place_starting_terrian()
	elif (game_master.game_state == game_master.GameState.PLACE_TERRIAN):
		switch_state_placing_terrian()
	else:
		switch_state_inactive()


func _on_button_mouse_entered() -> void:
	switch_state_inactive()


func _on_starter_biome_display_hidden() -> void:
	switch_state_placing_terrian()


func ready_signals() -> void:
	self.biome_placed.connect(game_master._on_user_controler_biome_placed)
	game_master.player_change_state.connect(self.game_master_change_state)

	var starter_biome_banner = get_node("/" + data_node_ref.UI_BIOMES_START).get_child(0)
	starter_biome_banner.mouse_entered.connect(self._on_starter_terrian_banner_mouse_entered)
	starter_biome_banner.mouse_exited.connect(self._on_starter_terrian_banner_mouse_exited)

	var starting_btns = get_tree().get_nodes_in_group("starter_biome_btns")
	for btn in starting_btns:
		btn.mouse_entered.connect(self._on_button_mouse_entered)

	var data_terrian = get_node("/" + data_node_ref.DATA_TERRIAN)
	self.biome_placed.connect(data_terrian._on_user_controler_biome_placed)

	terrian_info_panel.mouse_entered.connect(self.switch_state_inactive)
	terrian_info_panel.mouse_exited.connect(self.switch_state_active)
	self.update_terrian_info_panel.connect(terrian_info_panel.update_display_info)
