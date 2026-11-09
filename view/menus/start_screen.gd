# start_screen.gd
class_name StartScreen
extends Control

## The first screen: the title, Play (to the match setup) and Quit. Built in code like the HUD.

const MATCH_SETUP_SCENE := "res://scenes/menus/match_setup_screen.tscn"


func _ready() -> void:
	theme = HudTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(MenuBackdrop.new())

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_child(column)

	var title := HudTheme.make_label("BsOW", 96)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("outline_size", 14)
	column.add_child(title)
	var tagline := HudTheme.make_label("Drop landers. Hold the land. Raze their towers.", HudTheme.TITLE_FONT_SIZE, HudTheme.MUTED)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(tagline)
	column.add_child(_spacer(26))

	var play := _menu_button("Play", true)
	play.name = "PlayButton"
	play.pressed.connect(func() -> void: get_tree().change_scene_to_file(MATCH_SETUP_SCENE))
	column.add_child(play)
	var quit := _menu_button("Quit")
	quit.name = "QuitButton"
	quit.pressed.connect(func() -> void: get_tree().quit())
	column.add_child(quit)


func _menu_button(text: String, is_primary: bool = false) -> Button:
	var button := HudTheme.make_button(text, is_primary)
	button.custom_minimum_size = Vector2(300, 58)
	button.add_theme_font_size_override("font_size", 24)
	return button


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	return spacer
