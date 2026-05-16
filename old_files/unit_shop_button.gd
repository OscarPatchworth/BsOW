#unit_shop_button.gd
class_name UnitShopButton
extends GameButton

# signals
signal buy_unit_action_req(req: Action)

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var unit: UnitData
var selector_manager: Node

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods
func get_unit() -> UnitData:
	return unit
func set_unit(new_unit: UnitData):
	unit = new_unit
	update_btn_view()


func update_btn_view():
	self.text = unit.name

### Connected Signals
func bind_selector(selector: Node):
	selector_manager = selector
	#print("Building_Shop_Button selector_manager bound")


func _pressed():
	var action_req = Action.new()
	action_req.type = Action.RequestType.BUY_UNIT
	#action_req.actor = selector_manager.self_player
	#action_req.target_lander = selector_manager.selected_lander
	action_req.unit_type = unit
	buy_unit_action_req.emit(action_req)
	#print("Emittting action request: \n" + str(action_req.get_action_dict()))
