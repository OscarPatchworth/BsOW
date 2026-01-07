#class_name ClassName
extends Control

# signals
#signal score_changed

# enums
enum BuildingDisplay {
    HIDE_ALL,
    BUILDING_DETAILS,
    BUY_BUILDING
}

# constants
#const MAX_SPEED = 200

# static variables

# @export variables

# remaining regular variables
var display_state: BuildingDisplay = BuildingDisplay.HIDE_ALL

# @onready variables
@onready var details_building_node:VBoxContainer = self.find_child("BuildingDetails")
@onready var buy_building_node:VBoxContainer = self.find_child("BuyBuilding")


###################################################################################################
###	Methods
func _ready() -> void:
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

func set_state_buy_building():
    set_display_state(BuildingDisplay.BUY_BUILDING)
##

func update_display():
    match display_state:
        BuildingDisplay.HIDE_ALL:
            details_building_node.hide()
            buy_building_node.hide()
        BuildingDisplay.BUILDING_DETAILS:
            details_building_node.show()
            buy_building_node.hide()
        BuildingDisplay.BUY_BUILDING:
            details_building_node.hide()
            buy_building_node.show()