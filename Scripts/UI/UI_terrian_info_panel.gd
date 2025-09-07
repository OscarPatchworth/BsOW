extends Panel

# signals
signal update_terrian_pannel_info(terrian)
# enums

# constants

# static variables
var label_biome: Label
var label_building: Label
var hbox_build_opts: HBoxContainer
var label_units: Label
var hbox_units: HBoxContainer
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

# remaining regular variables

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

	label_connected_lander = find_child("Connected Biomes")
	hbox_connected_lander = find_child("hbox_connected")

	# Ready refrences
	data_terrian = get_node("/" + data_node_ref.DATA_TERRIAN)
	game_master = get_node("/" + data_node_ref.GAME_MASTER)

	#Ready Signals
	self.update_terrian_pannel_info.connect(game_master.update_terrian_pannel_info)

	# Ready Other
	become_invisable()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func update_display_info(terrian_node, player_node) -> void:
	self.terrian = terrian_node
	self.player = player_node
	var display_info = generate_diaplay_info()
	
	# Update Info
	update_biome_label(display_info)
	# If (Has Building)
	update_building_label(display_info)
	# If (can_spawn)
	update_spawn_label(display_info)	
	update_unit_label(display_info)
	update_connected_lander_label(display_info)


func become_invisable() ->void:
	self.hide()


func become_visable() -> void:
	self.show()


func update_biome_label(display_info: Dictionary) -> void:
	label_biome.text = display_info["Biome"]


func update_building_label(display_info: Dictionary) -> void:
	if(display_info["Built"]):
		label_building.text = "Building: " + display_info["Built"]
		hbox_build_opts.hide()
	else:
		label_building.text = "Building: "
		if(display_info["Race_buildings"]):
			hbox_build_opts.show()
			generate_build_opt_btns(display_info["Race_buildings"])


func update_spawn_label(display_info: Dictionary) -> void:
	label_spawn.text = "Spawn Units: "
	if(display_info["can_spawn"]):
		hbox_spawn_opts.show()
		generate_spawn_opt_btns(display_info["race_spawn"])
	else:
		hbox_spawn_opts.hide()


func update_unit_label(display_info: Dictionary) -> void:
	label_units.text = "Units on Lander: " + str(display_info["units"].size())
	hbox_units.hide()


func update_connected_lander_label(display_info: Dictionary) -> void:
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

	for lander in connected_landers:
		var new_lander_icon_btn = Button.new()
		new_lander_icon_btn.icon = lander.biome.poker_icon
		hbox_connected_lander.add_child(new_lander_icon_btn)



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

### Connected Signals
