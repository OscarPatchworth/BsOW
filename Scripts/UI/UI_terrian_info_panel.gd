extends Panel

# signals
signal update_terrian_pannel_info(terrian)
# enums

# constants

# static variables
var label_biome: Label
var label_building: Label
var hbox_build_opts: HBoxContainer
var terrian_node: Node3D

var data_terrian
var game_master

# @export variables
@export var building_opt_btn: PackedScene

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
func update_display_info(terrian_info: Dictionary) -> void:
	#print("Update Terrian Panel info signal recived from Player_Cntrl  ||  " + str(terrian_info["Biome"]))
	
	# Update Info
	label_biome.text = terrian_info["Biome"]
	# If (Has Building)
	if(terrian_info["Built"]):
		label_building.text = "Building: " + terrian_info["Built"]
		hbox_build_opts.hide()
	else:
		label_building.text = "Building: "
		if(terrian_info["Race_buildings"]):
			hbox_build_opts.show()
			generate_build_opt_btns(terrian_info["Race_buildings"])
	terrian_node = terrian_info["Terrian_node"]

func become_invisable() ->void:
	self.hide()


func become_visable() -> void:
	self.show()


func generate_build_opt_btns(build_opts: Array[BuildingRes]) -> void:
	free_children(hbox_build_opts)
	for building_opt in build_opts:
		var new_build_opt_btn = building_opt_btn.instantiate()
		new_build_opt_btn.set_build_data(building_opt)
		new_build_opt_btn.attempt_buy_build.connect(game_master.ply_attempt_build)
		new_build_opt_btn.build_on_terrian.connect(self.build_on_terrian)
		hbox_build_opts.add_child(new_build_opt_btn) 


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func build_on_terrian(build: BuildingRes) -> void:
	terrian_node.add_building(build)
	update_terrian_pannel_info.emit(terrian_node)

### Connected Signals
