extends Control

# signals
#signal score_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants

# static variables

# @export variables

# remaining regular variables
var selector_manager:GameManager

# @onready variables
@onready var lander_panel:Panel = self.find_child("LanderPanel")
@onready var biome_label: Label = lander_panel.find_child("BiomeLabel")
@onready var building_control:Control = self.find_child("BuildingControl")

###################################################################################################
###	Methods
func _ready() -> void:
	connect_signals()
	connect_wires()

	hide_lander_panel()


func hide_lander_panel():
	lander_panel.hide()


func show_lander_panel():	
	lander_panel.show()


func update_lander_panel():
	var cur_lander = selector_manager.get_selected_lander()
	biome_label.text = str(cur_lander.biome_data.name)

	if not cur_lander.has_building:
		building_control.set_state_building_shop()
	else:
		building_control.set_state_building_details()
		

### Signals and wires
func connect_signals():
	pass


func connect_wires():
	wire_selector_manager()


func wire_selector_manager():
	pass

### Connected Signals
func bind_selector(selector: GameManager):
	selector_manager = selector
	building_control.bind_selector(selector)


func display_landers_req(lander: Lander):
	show_lander_panel()
	update_lander_panel()
