class_name BtnTerrianSelect # Class Name
extends Button

# signals

# enums

# constants

# static variables
var data_node_ref
var data_terrian
var game_master
var player_node

# @export variables

# remaining regular variables
var allocated_biome
var is_toggled : bool

# @onready variables

###################################################################################################
###	Methods

###	_built_in_methods()

# Called when the node enters the scene tree for the first time.\
func _init() -> void:
	### Init node refs
	data_node_ref = self.get_node("../%DataNodeRefs")
	data_terrian = get_node("../").get_node("/" + data_node_ref.DATA_TERRIAN)
	game_master = get_node("../").get_node("/" + data_node_ref.GAME_MASTER)
	player_node = get_node("../").get_node("/" + data_node_ref.PLAYER)
	add_to_group("btn_starting_terrian")

	### Init allocated biome
	var rnd = randi_range(1, data_terrian.BiomeType.size()-1)
	allocated_biome = rnd

	### init btn func
	set_toggle_mode(true)
	set_action_mode(ACTION_MODE_BUTTON_RELEASE)
	is_toggled = false

	### init btn colour
	set_btn_colour()
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _toggled(toggled_on: bool) -> void:
	if(toggled_on):
		### toggle self
		is_toggled = true

		## untoggle the other btns
		var start_terrian_btn_group = get_tree().get_nodes_in_group("btn_starting_terrian")
		for i in start_terrian_btn_group:
			i.untoggle_other_starting_terrian_btns(self)
		
		## set placeable terrian to active btn terrian
		data_terrian.set_active_biome(allocated_biome)	


### overridden built-in virtual methods:
func _pressed() -> void:
	#data_terrian.set_active_biome(allocated_biome)
	pass

### Custom Methods
func untoggle_other_starting_terrian_btns(active_btn: Button) -> void:
	if (self != active_btn):
		set_pressed_no_signal(false)
		is_toggled = false


func delete_self() -> void:
	self.queue_free()


func set_btn_colour() -> void:
	var stylebox: StyleBox = self.get_theme_stylebox("normal")
	stylebox.bg_color = "#ff0000"
	self.add_theme_stylebox_override("normal", stylebox)

### Connected Signals
