extends GameManager

# signals
#signal score_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var ui_root: Control

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods
func _ready() -> void:
	ui_root = get_parent()
	assert(ui_root is Control)


### Connected Signals

func display_landers_req(lander: Lander):
	print("Player_UI recieved display landers req")
