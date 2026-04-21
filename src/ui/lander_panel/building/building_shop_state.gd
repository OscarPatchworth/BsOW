#building_shop_state.gd
extends VBoxContainer

# signals
signal build_action_req(action_request)

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var selector_manager:Node

# @export variables

# remaining regular variables
var cur_lander: Lander


# @onready variables
@onready var shop_label: Label = self.find_child("BuildingShopLabel")
@onready var shop_buttons: HBoxContainer = self.find_child("BuildingButtons")

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Signals and Wires
func bind_selector(selector: Node):
	selector_manager = selector
	#print("BuildingShop slector_manager bound")


func update():
	cur_lander = selector_manager.get_selected_lander()
	#shop_label.text = cur_lander.biome_data.name
	update_shop_building_buttons()


func update_shop_building_buttons():
	free_children(shop_buttons)
	var buildings = selector_manager.self_player.species.buildings

	for building in buildings:
		var build_btn = BuildingShopButton.new()
		build_btn.bind_selector(selector_manager)
		build_btn.set_building(building)
		build_btn.build_action_req.connect(self.fwd_build_action_req)

		shop_buttons.add_child(build_btn)


func fwd_build_action_req(action_req: Action):
	action_req.target_lander = cur_lander
	build_action_req.emit(action_req)
