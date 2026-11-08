# movement_panel.gd
class_name MovementPanel
extends Panel

## Pick which units to move from one lander to a connected, friendly or empty lander.

signal action_requested(action: Action)

var _lander_manager: LanderManager
var _from_lander: Lander
var _to_lander: Lander
var _selected_units: Array[UnitInstance] = []

@onready var _from_panel: Panel = find_child("FromPanel")
@onready var _to_panel: Panel = find_child("ToPanel")
@onready var _from_list: ListBox = _from_panel.find_child("VListBox")
@onready var _to_list: ListBox = _to_panel.find_child("VListBox")
@onready var _cancel_button: GameButton = find_child("CancelButton")
@onready var _move_button: GameButton = find_child("MoveButton")


func _ready() -> void:
	_from_list.item_pressed.connect(_on_from_list_item_pressed)
	_cancel_button.pressed.connect(close)
	_move_button.pressed.connect(_on_move_button_pressed)


#region Public API
func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_manager = lander_manager


func open(from_lander: Lander, to_lander: Lander) -> void:
	if from_lander == null or to_lander == null:
		push_warning("MovementPanel | open() needs both landers")
		return
	_from_lander = from_lander
	_to_lander = to_lander
	show()

	_from_panel.find_child("Label").text = from_lander.get_biome_data().get_display_name()
	_to_panel.find_child("Label").text = to_lander.get_biome_data().get_display_name()
	var unit_name := func(unit: UnitInstance) -> String: return unit.get_display_name()
	_from_list.set_items(from_lander.get_units(), unit_name)
	_to_list.set_items(to_lander.get_units(), unit_name)


func close() -> void:
	_from_lander = null
	_to_lander = null
	_selected_units = []
	hide()
#endregion


#region Accessors
func get_from_lander() -> Lander:
	return _from_lander


func get_to_lander() -> Lander:
	return _to_lander
#endregion


#region Signal handlers
func _on_from_list_item_pressed(unit: UnitInstance) -> void:
	if unit in _selected_units:
		_selected_units.erase(unit)
	else:
		_selected_units.append(unit)


func _on_move_button_pressed() -> void:
	var action := Action.create(Action.Type.MOVE_UNITS)
	action.set_source_lander(_from_lander)
	action.set_target_lander(_to_lander)
	action.set_units(_selected_units)
	action_requested.emit(action)
	close()
#endregion
