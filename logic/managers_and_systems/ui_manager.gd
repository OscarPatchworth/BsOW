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
		print("Lander has not building")
	else:
		print("Lander has building")
