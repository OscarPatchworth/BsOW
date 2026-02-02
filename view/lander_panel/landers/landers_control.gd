#landers_control.gd
extends VBoxContainer

# signals

# enums

# constants

# static vars
var selector_manager: GameManager

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods


### Connected Signals


## Calls
func bind_selector(selector: GameManager):
	selector_manager = selector
	#print("Lander Control selector_manager bound")



## Get/Set (er)s

### Connected Signals
