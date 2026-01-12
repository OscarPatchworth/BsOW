#building_shop_button.gd
class_name BuildingShopButton
extends GameButton

# signals
#signal score_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var building: BuildingData
var selector_manager: GameManager

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
func bind_selector(selector: GameManager):
	selector_manager = selector
	print("Building_Shop_Button selector_manager bound")


func _pressed():
	print(building.name)