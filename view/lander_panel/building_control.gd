#class_name ClassName
extends Control

# signals
#signal score_changed

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
@onready var building_details_node:VBoxContainer = self.find_child("BuildingDetails")
@onready var building_shop_node:VBoxContainer = self.find_child("BuildingShop")


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

func set_state_building_details():
	set_display_state(BuildingDisplay.BUILDING_DETAILS)

func set_state_building_shop():
	set_display_state(BuildingDisplay.BUILDING_SHOP)
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
	building_details_node.hide()
	building_shop_node.hide()


func update_building_details():
	building_shop_node.hide()
	building_details_node.show()


func update_building_shop():
	building_details_node.hide()
	building_shop_node.show()

### Signals and wires
func bind_selector(selector: GameManager):
	selector_manager = selector
	building_details_node.bind_selector(selector)
	building_shop_node.bind_selector(selector)


func connect_signals():
	pass


func connect_wires():
	pass
