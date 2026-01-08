#selector_manager.gd
extends GameManager

# signals
#signal score_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables

# @export variables

# remaining regular variables
var selected_lander:Lander

# @onready variables

###################################################################################################
###	Get/Set (er)s
func get_selected_lander() -> Lander:
	return selected_lander
func set_selected_lander(lander: Lander):
	selected_lander = lander


### Connected Signals
func select_lander_req(lander: Lander):
	set_selected_lander(lander)