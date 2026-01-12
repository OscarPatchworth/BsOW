#buy_building_view.gd
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
@onready var shop_label: Label = self.find_child("BuildingShopLabel")

###################################################################################################
###	Methods


### Signals and Wires
func bind_selector(selector: GameManager):
	selector_manager = selector
	print("BuildingShop slector_manager bound")


func update():
	var cur_lander = selector_manager.get_selected_lander()
	shop_label.text = cur_lander.biome_data.name
