# game_over_panel.gd
class_name GameOverPanel
extends PanelContainer

## Shown when the game ends: Victory or Defeat, why, and Main menu / Keep looking / Play again
## (the same race and number of AIs: MatchRequest keeps them).

const MAIN_MENU_SCENE := "res://scenes/menus/start_screen.tscn"

var _title: Label
var _reason: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(520, 0)
	add_theme_stylebox_override("panel", HudTheme.panel_style(HudTheme.BACKGROUND_SOLID, 14, 26))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	_title = HudTheme.make_label("", 44)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_reason = HudTheme.make_label("", HudTheme.FONT_SIZE, HudTheme.MUTED)
	_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_reason)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	var main_menu := HudTheme.make_button("Main menu")
	main_menu.name = "MainMenuButton"
	main_menu.pressed.connect(func() -> void: get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	buttons.add_child(main_menu)
	var keep_looking := HudTheme.make_button("Keep looking")
	keep_looking.pressed.connect(hide)
	var play_again := HudTheme.make_button("Play again", true)
	play_again.name = "PlayAgainButton"
	play_again.pressed.connect(func() -> void: get_tree().reload_current_scene())
	buttons.add_child(keep_looking)
	buttons.add_child(play_again)
	box.add_child(buttons)
	hide()


func open(winner: Actor, player: Player) -> void:
	if winner == player:
		_title.text = "Victory!"
		_title.add_theme_color_override("font_color", HudTheme.GOOD)
		_reason.text = "Every enemy command tower has been razed."
	else:
		_title.text = "Defeat"
		_title.add_theme_color_override("font_color", HudTheme.BAD)
		_reason.text = "Your command tower was razed." if winner != null else "Nobody is left standing."
		if winner != null:
			_reason.text += " %s wins." % winner.get_display_name()
	show()
