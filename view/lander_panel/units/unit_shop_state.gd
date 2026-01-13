#unit_shop_state.gd
extends VBoxContainer

# signals
#signal score_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var selector_manager: GameManager

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods


### Connected Signals
func bind_selector(selector: GameManager):
	selector_manager = selector
	#print("UnitShop slector_manager bound")


## Calls
func update():
	pass
