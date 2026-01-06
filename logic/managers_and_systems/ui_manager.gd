extends Control

# signals
#signal score_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods
func _ready() -> void:
	pass


### Connected Signals

func display_landers_req(lander: Lander):
	print("Player_UI recieved display landers req")
