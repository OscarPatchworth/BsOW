# building_shop_button.gd
class_name BuildingShopButton
extends GameButton

## Requests placing one kind of building.

signal action_requested(action: Action)

var _building_data: BuildingData


func _pressed() -> void:
	var action := Action.create(Action.Type.PLACE_BUILDING)
	action.set_building_data(_building_data)
	action_requested.emit(action)


#region Accessors
func get_building_data() -> BuildingData:
	return _building_data


func set_building_data(value: BuildingData) -> void:
	_building_data = value
	text = value.get_display_name()
#endregion
