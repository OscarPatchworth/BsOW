# unit_lander_button.gd
class_name UnitLanderButton
extends GameButton

## A unit on the selected lander. Toggle on/off to add/remove it from the selection.

signal unit_selected(unit: UnitInstance)
signal unit_deselected(unit: UnitInstance)

var _unit: UnitInstance


func _init() -> void:
	toggle_mode = true


func _toggled(is_on: bool) -> void:
	if is_on:
		unit_selected.emit(_unit)
	else:
		unit_deselected.emit(_unit)


#region Accessors
func get_unit() -> UnitInstance:
	return _unit


func set_unit(value: UnitInstance) -> void:
	_unit = value
	text = value.get_display_name()
	icon = value.get_icon()
#endregion
