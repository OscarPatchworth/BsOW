# purchase_panel.gd
class_name PurchasePanel
extends Panel

## The market shown in the buying phase: pick one of your landers, then something to buy on it.

signal action_requested(action: Action)
signal market_closed()

var _lander_manager: LanderManager
var _player: Player
var _active_lander: Lander

@onready var _landers_list: ListBox = find_child("LandersListBox")
@onready var _market_list: ListBox = find_child("MarketListBox")
@onready var _finish_button: GameButton = find_child("FinishButton")


func _ready() -> void:
	hide()
	_landers_list.item_pressed.connect(_on_landers_list_item_pressed)
	_market_list.item_pressed.connect(_on_market_list_item_pressed)
	_finish_button.pressed.connect(_on_finish_button_pressed)


#region Public API
func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_manager = lander_manager


func bind_player(player: Player) -> void:
	_player = player


func open_market() -> void:
	show()
	var landers := _lander_manager.get_landers_owned_by(_player)
	_landers_list.set_items(landers, func(lander: Lander) -> String: return lander.get_biome_data().get_display_name())

	# Disable landers with nothing to buy.
	var buttons: Array[Node] = await _landers_list.get_buttons()
	for i in buttons.size():
		if landers[i].get_purchasables(_player).is_empty():
			(buttons[i] as Button).disabled = true
#endregion


#region Signal handlers
func _on_landers_list_item_pressed(lander: Lander) -> void:
	_active_lander = lander
	_market_list.set_items(lander.get_purchasables(_player),
		func(purchasable: Variant) -> String: return purchasable.get_display_name())


func _on_market_list_item_pressed(purchasable: Resource) -> void:
	var action := Action.create(Action.Type.PURCHASE)
	action.set_target_lander(_active_lander)
	action.set_purchasable(purchasable)
	action_requested.emit(action)


func _on_finish_button_pressed() -> void:
	_landers_list.clear()
	_market_list.clear()
	market_closed.emit()
#endregion
