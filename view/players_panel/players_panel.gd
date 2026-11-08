# players_panel.gd
class_name PlayersPanel
extends Panel

## Turn order list with the active actor highlighted.

const SETUP_MARGIN_TOP: float = 0.01
const SETUP_MARGIN_RIGHT: float = 0.005

var _turn_manager: TurnManager

@onready var _players_list: ItemList = find_child("ItemList")


#region Public API
func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager


func show_turn_order() -> void:
	_players_list.clear()
	for actor_name in _turn_manager.get_turn_order_names():
		_players_list.add_item(actor_name, null, false)


func highlight_active_actor(active_actor: Actor) -> void:
	_players_list.deselect_all()
	for i in _players_list.item_count:
		var is_active := _players_list.get_item_text(i) == active_actor.name
		_players_list.set_item_custom_bg_color(i, Color.PEACH_PUFF if is_active else Color.TRANSPARENT)
		_players_list.set_item_custom_fg_color(i, Color.MEDIUM_BLUE if is_active else Color.GRAY)
	_players_list.queue_redraw()


func apply_game_state(state: TurnManager.GameState) -> void:
	match state:
		TurnManager.GameState.SETUP:
			# Tuck the panel into the top-right corner during setup, keeping its size.
			var height := anchor_bottom - anchor_top
			var width := anchor_right - anchor_left
			anchor_top = SETUP_MARGIN_TOP
			anchor_bottom = SETUP_MARGIN_TOP + height
			anchor_right = 1.0 - SETUP_MARGIN_RIGHT
			anchor_left = anchor_right - width
		TurnManager.GameState.MAIN_LOOP:
			show()
#endregion
