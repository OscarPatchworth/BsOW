#lander_control.gd
extends VBoxContainer

# signals

# enums

# constants

# static vars
var selector_manager: GameManager
var lander_manager: GameManager

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
	#var connected_landers: Array[Landers]
	#connected_landers = cur_lander.get_connected_landers()

	pass



### Connected Signals


## Calls
func bind_selector(selector: GameManager):
	selector_manager = selector
	#print("Lander Control selector_manager bound")


func bind_lander_manager(lm: GameManager):
	lander_manager = lm
	#print("Lander Manager bound to Lander_Control")


## Get/Set (er)s

### Connected Signals
