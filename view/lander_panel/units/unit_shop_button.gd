# unit_shop_button.gd
class_name UnitShopButton
extends GameButton

## Requests buying one kind of unit (a PURCHASE; the lander is filled in by the panel).

signal action_requested(action: Action)

var _unit_data: UnitData


func _pressed() -> void:
	var action := Action.create(Action.Type.PURCHASE)
	action.set_purchasable(_unit_data)
	action_requested.emit(action)


#region Accessors
func get_unit_data() -> UnitData:
	return _unit_data


func set_unit_data(value: UnitData) -> void:
	_unit_data = value
	text = value.get_display_name()
#endregion
