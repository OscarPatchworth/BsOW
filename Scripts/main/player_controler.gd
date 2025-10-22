extends Node3D

# signals
signal mouse_moved
signal biome_placed(ply_state : PlayerControlerStateMachine, spawn_spot : Dictionary)
signal update_terrian_info_panel(terrian_info: Dictionary)
signal escape_pressed
signal show_terrina_info_panel
signal occupied_units_updated

# enums
enum PlayerControlerStateMachine {
		INACTIVE, 
		PLACE_STARTING_TERRIAN, 
		PLACING_TERRIAN, 
		MOVE_UNITS, 
		COMBAT, 
		RENFORCE
}


enum CombatStateMachine {
	INACTIVE,
	HOLDING_CLICK,
	FIGHT
}

# constants
const RAY_LENGTH = 100

# static variables
var data_node_ref
var data_store
var game_master
var terrian_info_panel
var data_ply
var race: RaceRes

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
var combat_state: CombatStateMachine
var held_combat_lander: Terrian

# @onready variables
func _ready() -> void:
	data_node_ref = get_node("/root/Node3D/Data/DataNodeRefs")
	data_store = get_node("/" + data_node_ref.DATA_TERRIAN)
	game_master = get_node("/" + data_node_ref.GAME_MASTER)
	terrian_info_panel = get_node(data_node_ref.UI_TERRIAN_INFO)
	data_ply = get_node(data_node_ref.DATA_PLAYER)
	race = load(data_ply.RACE_APE_REF)

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
		PlayerControlerStateMachine.COMBAT:
			update_combat()
	

func _input(event: InputEvent) -> void:
	match player_state:
		PlayerControlerStateMachine.INACTIVE:
			pass
		PlayerControlerStateMachine.PLACING_TERRIAN:
			input_placing_terrian(event)
		PlayerControlerStateMachine.PLACE_STARTING_TERRIAN:
			input_place_starting_terrian(event)
		PlayerControlerStateMachine.COMBAT:
			input_combat(event)

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


func switch_state_move_units() -> void:
	check_terrain_paceable_sence.hide()
	player_state = PlayerControlerStateMachine.MOVE_UNITS
	combat_state = CombatStateMachine.INACTIVE


func switch_state_combat() -> void:
	check_terrain_paceable_sence.hide()
	player_state = PlayerControlerStateMachine.COMBAT
	combat_state = CombatStateMachine.INACTIVE


### Update() states

func update_placing_terrian() -> void:
	if check_terrain_paceable_sence:
		move_to_mouse_pos(check_terrain_paceable_sence)


func update_place_starting_terrian() -> void:
	if check_terrain_paceable_sence:
		move_to_mouse_pos(check_terrain_paceable_sence)


func update_combat() -> void:
	pass


func update_move_units() -> void:
	pass


### Input() states

func input_placing_terrian(event: InputEvent) -> void:
	if event.is_action_released("left_click") and !raycat_island() and (is_terrian_placeable):
		spawn_terrian()
	elif event.is_action_pressed("shifting") and !raycat_island():
		check_terrain_paceable_sence.show()
	elif event.is_action_released("shifting"):
		check_terrain_paceable_sence.hide()
	elif event.is_action_released("esc"):
		escape_pressed.emit()
	elif event.is_action_released("right_click"):
		var raycast_terrian = raycat_island()
		if (raycast_terrian):
			# show panel
			show_terrina_info_panel.emit()
			# get terrian data
			var terrian_obj = raycast_terrian["collider"].get_parent()
			generate_and_emit_terrian_banner_info(terrian_obj)


func input_place_starting_terrian(event: InputEvent) -> void:
	input_placing_terrian(event)


func input_move_units(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		var raycast_terrian = raycat_island()
		if (raycast_terrian):
			combat_state = CombatStateMachine.HOLDING_CLICK
			held_combat_lander = raycast_terrian["collider"].get_parent()
			#print(held_combat_lander.biome.name)

	if event.is_action_released("left_click"):
		combat_state = CombatStateMachine.INACTIVE
		if(held_combat_lander):
			var raycast_terrian = raycat_island()
			if (raycast_terrian):
				var target_lander = raycast_terrian["collider"].get_parent()
				if(target_lander in held_combat_lander.get_connected_landers()):
					var moving_units = held_combat_lander.units
					for unit in moving_units:
						if unit not in target_lander.units:
							target_lander.add_ext_unit(unit)
							held_combat_lander.rvm_unit(unit)
		held_combat_lander = null		
		occupied_units_updated.emit()
			
	elif event.is_action_released("right_click"):
		var raycast_terrian = raycat_island()
		if (raycast_terrian):
			# show panel
			show_terrina_info_panel.emit()
			# get terrian data
			var terrian_obj = raycast_terrian["collider"].get_parent()
			generate_and_emit_terrian_banner_info(terrian_obj)


func input_combat(event: InputEvent) -> void:
	if combat_state != CombatStateMachine.FIGHT:
		input_move_units(event)


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
		game_master.GameState.PLACE_TERRIAN:
			switch_state_placing_terrian()
		game_master.GameState.MOVE_UNITS:
			switch_state_move_units()
		game_master.GameState.COMBAT:
			switch_state_combat()


func generate_and_emit_terrian_banner_info(terrian_obj) -> void:
	# emit data
	update_terrian_info_panel.emit(terrian_obj, self)


func set_state_inactive(): # To be called by GM
	switch_state_inactive()

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
	# Biome_placed->Game_master
	self.biome_placed.connect(game_master._on_user_controler_biome_placed)
	# Game_master -> State overide
	game_master.player_change_state.connect(self.game_master_change_state)

	# Starting Biome Bannner #
	var starter_biome_banner = get_node("/" + data_node_ref.UI_BIOMES_START).get_child(0)
	# Mouse ON/OFF -> self inactive/active state
	starter_biome_banner.mouse_entered.connect(self._on_starter_terrian_banner_mouse_entered)
	starter_biome_banner.mouse_exited.connect(self._on_starter_terrian_banner_mouse_exited)
	# Mouse ON Biome Btn -> self inactive
	var starting_btns = get_tree().get_nodes_in_group("starter_biome_btns")
	for btn in starting_btns:
		btn.mouse_entered.connect(self._on_button_mouse_entered)

	# Biome_placed -> data_terrian.biome_placed
	var data_terrian = get_node("/" + data_node_ref.DATA_TERRIAN)
	self.biome_placed.connect(data_terrian._on_user_controler_biome_placed)

	# Terrain Pannel #
	# Mouse ON/OFF -> self inactive/active
	terrian_info_panel.mouse_entered.connect(self.switch_state_inactive)
	terrian_info_panel.mouse_exited.connect(self.switch_state_active)
	# self.terrian_clicked -> banner.show_info
	self.update_terrian_info_panel.connect(terrian_info_panel.update_display_info)
	# self -> banner show/hide
	self.escape_pressed.connect(terrian_info_panel.become_invisable)
	self.show_terrina_info_panel.connect(terrian_info_panel.become_visable)
	# self.Changed units array -> banner.update()
	self.occupied_units_updated.connect(terrian_info_panel.update_display_info)
