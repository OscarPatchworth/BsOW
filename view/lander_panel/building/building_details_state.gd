# building_details_state.gd
class_name BuildingDetailsState
extends VBoxContainer

## Shows the building on the selected lander.

var _selector_manager: SelectorManager

@onready var _name_label: Label = find_child("BuildingNameLabel")


func bind_selector_manager(selector_manager: SelectorManager) -> void:
	_selector_manager = selector_manager


func refresh() -> void:
	var building := _selector_manager.get_selected_lander().get_building()
	_name_label.text = building.get_display_name() if building != null else ""
