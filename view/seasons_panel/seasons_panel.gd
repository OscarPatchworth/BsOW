# seasons_panel.gd
class_name SeasonsPanel
extends Panel

## The season cycle with the current season highlighted.

var _turn_manager: TurnManager
var _season_names: Array[String] = []

@onready var _labels_box: HBoxContainer = find_child("HBoxContainer")


#region Public API
func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager


func show_seasons() -> void:
	for child in _labels_box.get_children():
		child.queue_free()
	_season_names = _turn_manager.get_season_names()
	for season_name in _season_names:
		var label := Label.new()
		label.text = TextUtils.to_title_case(season_name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_vertical = Control.SIZE_FILL
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_labels_box.add_child(label)

	await get_tree().process_frame  # Let the old labels free and the layout settle.
	highlight_season(0)


func highlight_season(season_index: int) -> void:
	print("SeasonsPanel | Current season: " + _season_names[season_index])
	for i in _labels_box.get_child_count():
		var stylebox := StyleBoxFlat.new()
		if i == season_index:
			var season := TurnManager.season_from_name(_season_names[season_index])
			stylebox.bg_color = TurnManager.get_season_color(season)
		else:
			stylebox.bg_color = Color.DIM_GRAY
		(_labels_box.get_child(i) as Label).add_theme_stylebox_override("normal", stylebox)


func apply_game_state(state: TurnManager.GameState) -> void:
	match state:
		TurnManager.GameState.SETUP:
			hide()
		TurnManager.GameState.MAIN_LOOP:
			show()
#endregion
