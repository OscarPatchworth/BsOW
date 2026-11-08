# building_shop_button.gd
class_name BuildingShopButton
extends GameButton

## Requests buying one kind of building (a PURCHASE; the lander is filled in by the panel).

signal action_requested(action: Action)

var _building_data: BuildingData


func _pressed() -> void:
	var action := Action.create(Action.Type.PURCHASE)
	action.set_purchasable(_building_data)
	action_requested.emit(action)


#region Accessors
func get_building_data() -> BuildingData:
	return _building_data


func set_building_data(value: BuildingData) -> void:
	_building_data = value
	text = value.get_display_name()
#endregion
