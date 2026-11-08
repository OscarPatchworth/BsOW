# unit_shop_state.gd
class_name UnitShopState
extends VBoxContainer

## Buttons for each unit the player's species can buy on the selected lander.

signal action_requested(action: Action)

var _selector_manager: SelectorManager

@onready var _buttons: HBoxContainer = find_child("UnitButtons")


func bind_selector_manager(selector_manager: SelectorManager) -> void:
	_selector_manager = selector_manager


func refresh() -> void:
	for child in _buttons.get_children():
		child.queue_free()
	for unit_data in _selector_manager.get_player().get_species().get_units():
		var button := UnitShopButton.new()
		button.set_unit_data(unit_data)
		button.action_requested.connect(action_requested.emit)
		_buttons.add_child(button)
