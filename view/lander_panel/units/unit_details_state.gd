# unit_details_state.gd
class_name UnitDetailsState
extends VBoxContainer

## Details about the units on the selected lander. (Nothing to show yet.)

var _selector_manager: SelectorManager


func bind_selector_manager(selector_manager: SelectorManager) -> void:
	_selector_manager = selector_manager


func refresh() -> void:
	pass
