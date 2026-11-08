# lander_control.gd
class_name LanderControl
extends VBoxContainer

## Neighbouring landers (click to move/attack) and the selected lander's units (toggle to choose).

signal refreshed()
signal action_requested(action: Action)

## The Player this HUD belongs to (set in player.tscn).
@export var player: Actor

var _selector_manager: SelectorManager
var _lander_manager: LanderManager
var _lander: Lander

@onready var _landers_flow: HFlowContainer = find_child("Landers")
@onready var _units_flow: HFlowContainer = find_child("Units")


#region Public API
func bind_selector_manager(selector_manager: SelectorManager) -> void:
	_selector_manager = selector_manager


func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_manager = lander_manager


func refresh() -> void:
	_lander = _selector_manager.get_selected_lander()
	if _lander == null:
		push_warning("LanderControl | refresh() with no lander selected")
		return
	_refresh_connected_landers()
	_refresh_units()
	refreshed.emit()
#endregion


#region Signal handlers
func _on_lander_button_action_requested(action: Action) -> void:
	action.set_source_lander(_selector_manager.get_selected_lander())
	action.set_target_lander(_selector_manager.get_target_lander())
	action.set_units(_selector_manager.get_selected_units())
	action_requested.emit(action)
#endregion


#region Private
func _refresh_connected_landers() -> void:
	for child in _landers_flow.get_children():
		child.queue_free()

	for lander in _lander_manager.get_connected_landers(_lander):
		var button := ConnectedLanderButton.new()
		button.set_lander(lander)
		var owner_actor := lander.get_owner_actor()
		if owner_actor == null:
			button.set_display_state(ConnectedLanderButton.DisplayState.NEUTRAL)
		elif owner_actor == player:
			button.set_display_state(ConnectedLanderButton.DisplayState.ALLY)
		else:
			button.set_display_state(ConnectedLanderButton.DisplayState.ENEMY)
		_landers_flow.add_child(button)
		button.lander_pressed.connect(_selector_manager.set_target_lander)
		button.action_requested.connect(_on_lander_button_action_requested)


func _refresh_units() -> void:
	for child in _units_flow.get_children():
		child.queue_free()

	for unit in _lander.get_units():
		var button := UnitLanderButton.new()
		button.set_unit(unit)
		_units_flow.add_child(button)
		button.unit_selected.connect(_selector_manager.add_selected_unit)
		button.unit_deselected.connect(_selector_manager.remove_selected_unit)
#endregion
