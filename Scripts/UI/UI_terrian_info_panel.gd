extends Panel

# signals
signal update_terrian_pannel_info(terrian)
# enums

# constants

# static variables
var label_biome: Label
var label_owner: Label
var label_placer: Label
var label_upkeep: Label
var label_abilities: Label

var label_building: Label
var hbox_build_opts: HBoxContainer

var label_units: Label
var hbox_units: HBoxContainer
var label_selected_units: Label
var hbox_selected_units: HBoxContainer

var label_spawn: Label
var hbox_spawn_opts: HBoxContainer

var label_connected_lander: Label
var hbox_connected_lander: HBoxContainer

var terrian: Node3D
var player: Node3D

var data_terrian
var game_master

# @export variables
@export var building_opt_btn: PackedScene
@export var spawn_opt_btn: PackedScene
@export var unit_in_lander_btn: PackedScene

# remaining regular variables
var player_phase = 0
var selected_unit_landers: Array[Unit]
var display_info

# @onready variables
@onready var data_node_ref = get_node("%DataNodeRefs")

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ready Labels
	label_biome = find_child("Biome")
	label_building = find_child("Building")
	hbox_build_opts = find_child("Building_options")

	label_spawn = find_child("Spawn_units")
	hbox_spawn_opts = find_child("Spawn_options")

	label_units = find_child("Units")
	hbox_units = find_child("units_hbox")
	label_selected_units = find_child("selected_units_label")
	hbox_selected_units = find_child("selected_units")

	label_connected_lander = find_child("Connected Biomes")
	hbox_connected_lander = find_child("hbox_connected")

	label_owner = find_child("Owner")
	label_placer = find_child("Placer")
	label_upkeep = find_child("Upkeep")
	label_abilities = find_child("Abilities")

	# Ready refrences
	data_terrian = get_node("/" + data_node_ref.DATA_TERRIAN)
	game_master = get_node("/" + data_node_ref.GAME_MASTER)

	#Ready Signals
	ready_signals()

	# Ready Other
	become_invisable()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func update_display_info(terrian_node, player_node) -> void:
	self.terrian = terrian_node
	self.player = player_node
	display_info = generate_diaplay_info()
	
	if(player_phase != game_master.GameState.MOVE_UNITS):
		# Update Info
		update_biome_label(display_info)
		# If (Has Building)
		update_building_label(display_info)
		# If (can_spawn)
		update_spawn_label(display_info)	
		update_unit_label(display_info)
		update_connected_lander_label(display_info)
	else:
		# Update Info
		update_biome_label(display_info)
		# If (Has Building)
		update_building_label(display_info)
		update_connected_lander_label(display_info)
		update_units_hbox(display_info)
		
		free_children(hbox_build_opts)
		hbox_spawn_opts.hide()
		label_spawn.hide()
	
	# Hide un-set fields
	label_owner.hide()
	label_placer.hide()
	label_upkeep.hide()
	label_abilities.hide()

func become_invisable() ->void:
	self.terrian = null
	self.player = null
	self.hide()


func become_visable() -> void:
	self.show()


func update_biome_label(display_info: Dictionary = display_info) -> void:
	label_biome.text = display_info["Biome"]


func update_building_label(display_info: Dictionary = display_info) -> void:
	if(display_info["Built"]):
		label_building.text = "Building: " + display_info["Built"]
		hbox_build_opts.hide()
	elif(player_phase != game_master.GameState.MOVE_UNITS):
		label_building.text = "Building: "
		if(display_info["Race_buildings"]):
			hbox_build_opts.show()
			generate_build_opt_btns(display_info["Race_buildings"])


func update_spawn_label(display_info: Dictionary = display_info) -> void:
	label_spawn.text = "Spawn Units: "
	if(display_info["can_spawn"]):
		hbox_spawn_opts.show()
		generate_spawn_opt_btns(display_info["race_spawn"])
	else:
		hbox_spawn_opts.hide()


func update_unit_label(display_info: Dictionary = display_info) -> void:
	label_units.text = "Units on Lander: " + str(display_info["units"].size())
	hbox_units.hide()
	hbox_selected_units.hide()


func update_connected_lander_label(display_info: Dictionary = display_info) -> void:
	label_connected_lander.text = "Connected Terrian: " + str(display_info["connected_landers"].size())
	generate_connected_lander_btns(display_info["connected_landers"])

func generate_build_opt_btns(build_opts: Array[BuildingRes]) -> void:
	free_children(hbox_build_opts)
	for building_opt in build_opts:
		var valid_build:bool
		
		if(building_opt.unique_build):
			valid_build = true
			var all_buildings = get_tree().get_nodes_in_group("buildings")
			for build in all_buildings:
				if(build.build_res.name == building_opt.name and build.controler == player.get_parent().get_parent()):
					valid_build = false
		else: valid_build = true

		if(valid_build):
			var new_build_opt_btn = building_opt_btn.instantiate()
			new_build_opt_btn.set_build_data(building_opt)
			
			new_build_opt_btn.attempt_buy_build.connect(game_master.ply_attempt_build)
			new_build_opt_btn.build_on_terrian.connect(self.build_on_terrian)
			
			hbox_build_opts.add_child(new_build_opt_btn) 


func generate_spawn_opt_btns(spawn_opts: Array[UnitRes]) -> void:
	free_children(hbox_spawn_opts)
	#var upcoming_code = 
	for spawn_opt in spawn_opts:
		var new_spawn_opt_btn = spawn_opt_btn.instantiate()
		new_spawn_opt_btn.set_unit_data(spawn_opt)
			
		new_spawn_opt_btn.attempt_buy_unit.connect(game_master.ply_attempt_buy_unit)
		new_spawn_opt_btn.spawn_unit_on_terrian.connect(self.add_unit)
			
		hbox_spawn_opts.add_child(new_spawn_opt_btn) 
	

func generate_connected_lander_btns(connected_landers: Array[Terrian]) -> void:
	free_children(hbox_connected_lander)
	var btn_script = load(data_node_ref.BTN_CONNECTED_LANDER)

	for lander in connected_landers:
		var new_lander_icon_btn = Button.new()
		new_lander_icon_btn.set_script(btn_script)
		new_lander_icon_btn.icon = lander.biome.poker_icon

		new_lander_icon_btn.lander_ref = lander

		new_lander_icon_btn.is_pressed.connect(move_selected_units_to_lander)
		hbox_connected_lander.add_child(new_lander_icon_btn)


func generate_inlander_units_btns(lander_units: Array[Unit]) -> void:
	free_children(hbox_units)
	free_children(hbox_selected_units)
	hbox_units.show()
	hbox_selected_units.show()


	for unit in lander_units:
		if(unit not in selected_unit_landers):
			var new_unit_btn = unit_in_lander_btn.instantiate()
			new_unit_btn.set_unit_data(unit)

			hbox_units.add_child(new_unit_btn)
		else:
			var new_unit_btn = unit_in_lander_btn.instantiate()
			new_unit_btn.set_unit_data(unit)
			new_unit_btn.set_pressed_no_signal(true)

			hbox_selected_units.add_child(new_unit_btn)



func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func build_on_terrian(build: BuildingRes) -> void:
	terrian.add_building(build)
	update_terrian_pannel_info.emit(terrian)


func add_unit(unit: UnitRes) -> void:
	terrian.add_unit(unit)
	update_terrian_pannel_info.emit(terrian)

func generate_diaplay_info() -> Dictionary:
	var info:Dictionary = {}
	info["Biome"] = terrian.biome.name
	info["Built"] = terrian.building_res.name if terrian.building_res else ""
	info["Terrian_node"] = terrian
	info["Race_buildings"] = player.race.buildings

	info["units"] = terrian.units
	info["can_spawn"] = terrian.building_res.can_spawn if terrian.building_res else false
	info["race_spawn"] = player.race.units

	info["connected_landers"] = terrian.get_connected_landers()
	return info


func update_player_phase(player_state: int):
	player_phase = player_state
	if(player and terrian):
		update_display_info(self.terrian, self.player)


func update_units_hbox(display_info: Dictionary = display_info):
	if(display_info):
		update_unit_label(display_info)
		generate_inlander_units_btns(display_info["units"])


func add_selected_unit_lander(target_unit: Unit):
	if(target_unit not in selected_unit_landers):
		selected_unit_landers.append(target_unit)
		##print("Added target unit to the selected units array")
	else:
		print("Unit already selected")
	update_units_hbox()


func add_mulitple_unit_landers(units: Array[Unit]):
	for unit in units:
		add_selected_unit_lander(unit)


func rmv_selected_unit_lander(target_unit: Unit):
	if(target_unit in selected_unit_landers):
		selected_unit_landers.erase(target_unit)
		#print("Unit rmv from selected units")
	else:
		print("Unit wasn't in selected to begin with")
	update_units_hbox()

		
func rmv_mulitple_unit_landers(units: Array[Unit]):
	for unit in units:
		rmv_selected_unit_lander(unit)
		

func move_selected_units_to_lander(lander: Terrian):
	print("UI info pannel move_selected_units_to_lander triggered")
	for unit in selected_unit_landers:
		if unit not in lander.units:
			lander.units.append(unit)
			self.terrian.units.erase(unit)
		else: print("Unit moving to lander appears to already exist on lander ...")
	rmv_mulitple_unit_landers(selected_unit_landers)



### Connected Signals
func ready_signals() -> void:
	#GameMaster updates player state -> update self.UI
	game_master.player_change_state.connect(self.update_player_phase)
	#
	self.update_terrian_pannel_info.connect(game_master.update_terrian_pannel_info)
