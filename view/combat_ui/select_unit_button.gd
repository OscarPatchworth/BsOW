# select_unit_button.gd
class_name SelectUnitButton
extends GameButton

## A button in the unit picker. Pressing it selects its unit for combat.

signal unit_selected(unit: UnitInstance)

var _unit: UnitInstance


func _pressed() -> void:
	unit_selected.emit(_unit)


#region Accessors
func get_unit() -> UnitInstance:
	return _unit


func set_unit(value: UnitInstance) -> void:
	_unit = value
	text = value.get_display_name() if value != null else ""
#endregion
