extends Control

# signals
#signal score_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants

# static variables

# @export variables

# remaining regular variables

# @onready variables
@onready var lander_panel:Panel = self.find_child("LanderPanel")
@onready var biome_label: Label = lander_panel.find_child("BiomeLabel")
@onready var building_control:Control = self.find_child("BuildingControl")

###################################################################################################
###	Methods
func _ready() -> void:
	hide_lander_panel()


func hide_lander_panel():
	lander_panel.hide()


func show_lander_panel():	
	lander_panel.show()

### Connected Signals

func display_landers_req(lander: Lander):
	show_lander_panel()
	update_lander_panel(lander)


func update_lander_panel(lander: Lander):
	biome_label.text = str(lander.biome_data.name)

	if not lander.has_building:
		building_control.set_state_buy_building()
	else:
		building_control.set_state_building_details()
		
