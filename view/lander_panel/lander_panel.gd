# lander_panel.gd
class_name LanderPanel
extends Panel

## Details for the currently selected lander: its biome, building, units and neighbours.

signal action_requested(action: Action)

var _selector_manager: SelectorManager

@onready var _building_control: BuildingControl = find_child("BuildingControl")
@onready var _unit_control: UnitControl = find_child("UnitControl")
@onready var _lander_control: LanderControl = find_child("LanderControl")
@onready var _biome_label: Label = find_child("BiomeLabel")


func _ready() -> void:
	_building_control.action_requested.connect(action_requested.emit)
	_unit_control.action_requested.connect(_on_unit_control_action_requested)
	_lander_control.action_requested.connect(action_requested.emit)


#region Public API
func bind_selector_manager(selector_manager: SelectorManager) -> void:
	_selector_manager = selector_manager
	_building_control.bind_selector_manager(selector_manager)
	_unit_control.bind_selector_manager(selector_manager)
	_lander_control.bind_selector_manager(selector_manager)
	_lander_control.refreshed.connect(selector_manager.clear_selected_units)


func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_control.bind_lander_manager(lander_manager)


func refresh() -> void:
	var lander := _selector_manager.get_selected_lander()
	if lander == null:
		return
	_biome_label.text = lander.get_biome_data().get_display_name()

	if lander.has_building():
		_building_control.show_details()
	else:
		_building_control.show_shop()

	if lander.is_full():
		_unit_control.show_details()
	else:
		_unit_control.show_shop()

	_lander_control.refresh()
#endregion


#region Signal handlers
func _on_unit_control_action_requested(action: Action) -> void:
	action.set_target_lander(_selector_manager.get_selected_lander())
	action_requested.emit(action)
#endregion
