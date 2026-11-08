# building_shop_state.gd
class_name BuildingShopState
extends VBoxContainer

## Buttons for each building the player's species can place on the selected lander.

signal action_requested(action: Action)

var _selector_manager: SelectorManager
var _lander: Lander

@onready var _buttons: HBoxContainer = find_child("BuildingButtons")


#region Public API
func bind_selector_manager(selector_manager: SelectorManager) -> void:
	_selector_manager = selector_manager


func refresh() -> void:
	_lander = _selector_manager.get_selected_lander()
	for child in _buttons.get_children():
		child.queue_free()
	for building_data in _selector_manager.get_player().get_species().get_buildings():
		var button := BuildingShopButton.new()
		button.set_building_data(building_data)
		button.action_requested.connect(_on_button_action_requested)
		_buttons.add_child(button)
#endregion


#region Signal handlers
func _on_button_action_requested(action: Action) -> void:
	action.set_target_lander(_lander)
	action_requested.emit(action)
#endregion
