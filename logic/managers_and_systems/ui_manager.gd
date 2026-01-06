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
