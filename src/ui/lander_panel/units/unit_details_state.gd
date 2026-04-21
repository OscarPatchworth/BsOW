#unit_details_state.gd
extends Node

# signals
#signal score_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var selector_manager: Node

# @export variables

# remaining regular variables
var cur_lander: Lander
var cur_actor: Actor


# @onready variables

###################################################################################################
###	Methods


### Connected Signals
func bind_selector(selector: Node):
	selector_manager = selector
	#print("UnitDetails slector_manager bound")


## Calls
func update():
	pass
