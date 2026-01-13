#building_details_state.gd
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
@onready var building_label: Label = self.find_child("BuildingNameLabel")

###################################################################################################
###	Methods


### Signals and Wires
func bind_selector(selector: GameManager):
	selector_manager = selector
	#print("BuildingDetails slector_manager bound")


## Calls
func update():
	var cur_lander = selector_manager.get_selected_lander()
	building_label.text = cur_lander.get_building().get_building_name()
