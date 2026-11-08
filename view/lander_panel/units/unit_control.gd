# unit_control.gd
class_name UnitControl
extends VBoxContainer

## The unit section of the lander panel: a shop while the lander has room, details when full.

signal action_requested(action: Action)

enum DisplayState {
	HIDDEN,
	DETAILS,
	SHOP,
}

var _display_state: DisplayState = DisplayState.HIDDEN

@onready var _details: UnitDetailsState = find_child("DetailsState")
@onready var _shop: UnitShopState = find_child("ShopState")


func _ready() -> void:
	_shop.action_requested.connect(action_requested.emit)
	_refresh()


#region Public API
func bind_selector_manager(selector_manager: SelectorManager) -> void:
	_details.bind_selector_manager(selector_manager)
	_shop.bind_selector_manager(selector_manager)


func show_details() -> void:
	set_display_state(DisplayState.DETAILS)


func show_shop() -> void:
	set_display_state(DisplayState.SHOP)


func hide_all() -> void:
	set_display_state(DisplayState.HIDDEN)
#endregion


#region Accessors
func get_display_state() -> DisplayState:
	return _display_state


func set_display_state(value: DisplayState) -> void:
	_display_state = value
	_refresh()
#endregion


#region Private
func _refresh() -> void:
	_details.visible = _display_state == DisplayState.DETAILS
	_shop.visible = _display_state == DisplayState.SHOP
	match _display_state:
		DisplayState.DETAILS:
			_details.refresh()
		DisplayState.SHOP:
			_shop.refresh()
#endregion
