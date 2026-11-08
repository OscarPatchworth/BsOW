# shop_button.gd
class_name ShopButton
extends Button

## "Buy Lycanth Halfbreed  🪙2 🍖2". Pressing it requests a PURCHASE on its lander.

signal action_requested(action: Action)

var _purchasable: Resource
var _target_lander: Lander


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	pressed.connect(_on_pressed)


func get_purchasable() -> Resource:
	return _purchasable


func set_purchasable(value: Resource) -> void:
	_purchasable = value
	var kind := "Build" if value is BuildingData else "Train"
	text = "%s %s   %s" % [kind, value.get("display_name"), HudTheme.format_cost(value.get_cost())]


func set_target_lander(value: Lander) -> void:
	_target_lander = value


## The PURCHASE this button requests (also used by tests).
func make_action() -> Action:
	var action := Action.create(Action.Type.PURCHASE)
	action.set_target_lander(_target_lander)
	action.set_purchasable(_purchasable)
	return action


func _on_pressed() -> void:
	action_requested.emit(make_action())
