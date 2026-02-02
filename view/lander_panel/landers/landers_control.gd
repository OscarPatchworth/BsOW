#landers_control.gd
extends VBoxContainer

# signals

# enums

# constants

# static vars
var selector_manager: GameManager

# @export variables

# remaining regular variables
var cur_lander: Lander
# @onready variables

###################################################################################################
###	Methods
func update():
	cur_lander = selector_manager.get_selected_lander()
	if cur_lander == null:
		print("Lander Control in player UI has null lander selected")
		return
	pass



### Connected Signals


## Calls
func bind_selector(selector: GameManager):
	selector_manager = selector
	#print("Lander Control selector_manager bound")



## Get/Set (er)s

### Connected Signals
