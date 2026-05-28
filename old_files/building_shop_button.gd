#building_shop_button.gd
#class_name BuildingShopButton
extends GameButton

# signals
signal build_action_req(action_request)

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var building: BuildingData
var selector_manager: Node

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods
func get_building() -> BuildingData:
	return building
func set_building(new_building: BuildingData):
	building = new_building
	update_btn_view()


func update_btn_view():
	self.text = building.name

### Connected Signals
func bind_selector(selector: Node):
	selector_manager = selector
	#print("Building_Shop_Button selector_manager bound")


func _pressed():
	var action_req = Action.new()
	action_req.type = Action.RequestType.PLACE_BUILDING
	#action_req.actor = selector_manager.self_player
	#action_req.target_lander = selector_manager.origin_lander
	action_req.building_type = building
	build_action_req.emit(action_req)
	#print("Emittting action request: \n" + str(action_req.get_action_dict()))
