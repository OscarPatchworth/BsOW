# players_panel.gd
extends Panel

#region Scene Refs
var turn_manager: TurnManager
@onready var players_list: ItemList = self.find_child("ItemList")
#endregion

###################################################################################################
#region Lifecycle
func game_state_changed(state: int) -> void:
	match state:
		0: pass  # Setup — position handled by scene layout
		1: self.show()  # Game Loop
#endregion

#region Binders
func bind_turn_manager(tm: TurnManager) -> void:
	turn_manager = tm
#endregion

#region Callbacks
func setup_turn_order_display() -> void:
	if turn_manager == null:
		print("Players Panel | Err | Calling null on turn_manager")
		return
	players_list.clear()
	for actor_name in turn_manager.get_turn_order_names():
		players_list.add_item(actor_name, null, false)

func actor_turn_changed(active_actor: Actor) -> void:
	players_list.deselect_all()
	for i in range(players_list.item_count):
		var is_active = players_list.get_item_text(i) == active_actor.name
		if is_active:
			players_list.set_item_custom_bg_color(i, Color.PEACH_PUFF)
			players_list.set_item_custom_fg_color(i, Color.MEDIUM_BLUE)
		else:
			players_list.set_item_custom_bg_color(i, Color.TRANSPARENT)
			players_list.set_item_custom_fg_color(i, Color.GRAY)
	players_list.queue_redraw()
#endregion

# End Of File
