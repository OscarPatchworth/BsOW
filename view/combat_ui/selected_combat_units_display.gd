# selected_combat_units_display.gd
class_name SelectedCombatUnitsDisplay
extends Control

## One unit slot in a CombatUnitsPanel: a colored fill bar, the unit's name,
## and a button to deselect the unit while still choosing.

signal unit_deselected(unit: UnitInstance)

## Values match Control's Side constants used by set_anchor_and_offset.
enum FillDirection {
	LEFT_TO_RIGHT = 0,
	RIGHT_TO_LEFT = 2,
}

enum DisplayState {
	SELECTING,
	READY,
}

const EMPTY_FILL: float = 0.64
const FILLED_FILL: float = 1.0

var _color: Color
var _fill_direction: FillDirection = FillDirection.LEFT_TO_RIGHT
var _display_state: DisplayState = DisplayState.SELECTING
var _unit: UnitInstance
var _fill_stylebox := StyleBoxFlat.new()

@onready var _button: GameButton = find_child("GameButton")
@onready var _fill: Panel = find_child("Fill")
@onready var _label: RichTextLabel = find_child("RichTextLabel")


func _ready() -> void:
	_fill.add_theme_stylebox_override("panel", _fill_stylebox)
	_button.pressed.connect(_on_button_pressed)


#region Public API
func show_outcome(outcome: CombatOutcome) -> void:
	set_display_state(DisplayState.READY)
	_label.text = str(outcome.get_total())  # Shows the total roll for now.
#endregion


#region Accessors
func get_color() -> Color:
	return _color


func set_color(value: Color) -> void:
	_color = value
	_fill_stylebox.bg_color = _color


func get_fill_direction() -> FillDirection:
	return _fill_direction


func set_fill_direction(value: FillDirection) -> void:
	_fill_direction = value


func get_display_state() -> DisplayState:
	return _display_state


func set_display_state(value: DisplayState) -> void:
	_display_state = value
	_refresh()


func get_unit() -> UnitInstance:
	return _unit


func set_unit(value: UnitInstance) -> void:
	_unit = value
	_refresh()
#endregion


#region Private
func _refresh() -> void:
	_fill_stylebox.bg_color = _color
	_refresh_fill()
	_label.text = _unit.get_display_name() if _unit != null else ""
	_button.disabled = _display_state != DisplayState.SELECTING


func _refresh_fill() -> void:
	var has_unit := _unit != null
	var amount := FILLED_FILL if has_unit else EMPTY_FILL
	_button.visible = has_unit
	if _fill_direction == FillDirection.LEFT_TO_RIGHT:
		_fill.set_anchor_and_offset(SIDE_LEFT, 0, 0)
		_fill.set_anchor_and_offset(SIDE_RIGHT, amount, 0)
	else:
		_fill.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
		_fill.set_anchor_and_offset(SIDE_LEFT, 1 - amount, 0)


func _on_button_pressed() -> void:
	unit_deselected.emit(_unit)
#endregion
