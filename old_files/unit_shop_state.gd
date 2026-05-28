#unit_shop_state.gd
extends VBoxContainer

# signals
signal buy_unit_action_req(req: Action)

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
@onready var shop_buttons: HBoxContainer = self.find_child("UnitButtons")

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func update_shop_buttons():
	free_children(shop_buttons)
	var units = selector_manager.self_player.species.units

	for unit in units:
		var unit_btn = UnitShopButton.new()
		unit_btn.bind_selector(selector_manager)
		unit_btn.set_unit(unit)
		unit_btn.buy_unit_action_req.connect(self.fwd_buy_unit_action_req)
		shop_buttons.add_child(unit_btn)

### Connected Signals
func bind_selector(selector: Node):
	selector_manager = selector
	#print("UnitShop slector_manager bound")


func fwd_buy_unit_action_req(req:Action):
	buy_unit_action_req.emit(req)
	

## Calls
func update():
	cur_lander = selector_manager.get_origin_lander()
	cur_actor = selector_manager.get_player()

	update_shop_buttons()
