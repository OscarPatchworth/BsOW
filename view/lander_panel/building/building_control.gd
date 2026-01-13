#Building_control.gd
extends Control

# signals
signal build_action_req(build_req)

# enums
enum BuildingDisplay {
	HIDE_ALL,
	BUILDING_DETAILS,
	BUILDING_SHOP
}

# constants
#const MAX_SPEED = 200

# static variables
var selector_manager:GameManager

# @export variables

# remaining regular variables
var display_state: BuildingDisplay = BuildingDisplay.HIDE_ALL

# @onready variables
@onready var details_node:VBoxContainer = self.find_child("DetailsState")
@onready var shop_node:VBoxContainer = self.find_child("ShopState")


###################################################################################################
###	Methods
func _ready() -> void:
	connect_signals()
	connect_wires()

	update_display()


func get_display_state() -> BuildingDisplay:
	return display_state
func set_display_state(new_state: BuildingDisplay):
	display_state = new_state
	update_display()

##
func set_state_hide():
	set_display_state(BuildingDisplay.HIDE_ALL)
	update_display()

func set_state_building_details():
	set_display_state(BuildingDisplay.BUILDING_DETAILS)
	update_display()

func set_state_building_shop():
	set_display_state(BuildingDisplay.BUILDING_SHOP)
	update_display()
##

func update_display():
	match display_state:
		BuildingDisplay.HIDE_ALL:
			update_hide_all()

		BuildingDisplay.BUILDING_DETAILS:
			update_building_details()

		BuildingDisplay.BUILDING_SHOP:
			update_building_shop()


func update_hide_all():
	details_node.hide()
	shop_node.hide()


func update_building_details():
	shop_node.hide()
	details_node.show()
	details_node.update()


func update_building_shop():
	details_node.hide()
	shop_node.show()
	shop_node.update()

### Signals and wires
func bind_selector(selector: GameManager):
	selector_manager = selector
	details_node.bind_selector(selector)
	shop_node.bind_selector(selector)
	#print("Building Control selector_manager bound")


func connect_signals():
	shop_node.build_action_req.connect(self.fwd_build_req)


func connect_wires():
	pass


func fwd_build_req(build_req: Action):
	build_action_req.emit(build_req)
