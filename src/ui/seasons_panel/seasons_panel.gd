# seasons_panel.gd
extends Panel

#region Scene Refs
var turn_manager: TurnManager
var game_seasons: Array
@onready var hbox: HBoxContainer = self.find_child("HBoxContainer")
#endregion

###################################################################################################
#region Lifecycle
func game_state_changed(state: int) -> void:
	match state:
		0: self.hide()  # Setup
		1: self.show()  # Game Loop
#endregion

#region Binders
func bind_turn_manager(tm: TurnManager) -> void:
	turn_manager = tm
#endregion

#region Callbacks
func seasons_generated() -> void:
	if turn_manager == null:
		print("Season Panel | Err | Calling null on turn manager")
		return
	free_children(hbox)
	game_seasons = turn_manager.get_season_order_names()
	for season in game_seasons:
		var new_label = Label.new()
		new_label.text = to_sentence_case(season)
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		new_label.size_flags_vertical = Control.SIZE_FILL
		new_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(new_label)
	await get_tree().process_frame
	season_changed(0)


func season_changed(sea_indx: int) -> void:
	if turn_manager == null:
		print("Season Panel | Err | Calling null on turn manager")
		return
	for i in range(hbox.get_child_count()):
		var label = hbox.get_child(i) as Label
		var new_sb = StyleBoxFlat.new()
		new_sb.bg_color = turn_manager.get_season_color(turn_manager.get_season(game_seasons[sea_indx])) if i == sea_indx else Color.DIM_GRAY
		label.add_theme_stylebox_override("normal", new_sb)
#endregion

#region Helpers
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func to_sentence_case(txt: String) -> String:
	var words = txt.split("_")
	for i in range(words.size()):
		words[i] = words[i].to_lower().capitalize()
	return " ".join(words)


# End Of File
