#building_details_view.gd
extends VBoxContainer

# signals
#signal score_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var selector_manager:GameManager

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods


### Signals and Wires
func bind_selector(selector: GameManager):
	selector_manager = selector
	print("BuildingDetails slector_manager bound")
