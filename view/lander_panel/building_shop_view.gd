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
var cur_lander: Lander


# @onready variables
@onready var shop_label: Label = self.find_child("BuildingShopLabel")
@onready var shop_buttons: HBoxContainer = self.find_child("BuildingButtons")

###################################################################################################
###	Methods


### Signals and Wires
func bind_selector(selector: GameManager):
	selector_manager = selector
	print("BuildingShop slector_manager bound")


func update():
	cur_lander = selector_manager.get_selected_lander()
	shop_label.text = cur_lander.biome_data.name


func update_shop_building_buttons():
	free_children(shop_buttons)


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()
