# connected_lander_button.gd
class_name ConnectedLanderButton
extends GameButton

## A neighbouring lander. Pressing it targets that lander and requests a move (or an attack if hostile).

signal lander_pressed(lander: Lander)
signal action_requested(action: Action)

enum DisplayState {
	NEUTRAL,
	ALLY,
	ENEMY,
}

const STYLE_DEFAULT: StyleBox = preload("res://view/lander_panel/landers/lander_button_default.res")
const STYLE_ALLY: StyleBox = preload("res://view/lander_panel/landers/lander_button_ally.res")
const STYLE_ENEMY: StyleBox = preload("res://view/lander_panel/landers/lander_button_enemy.res")

var _lander: Lander
var _display_state: DisplayState = DisplayState.NEUTRAL


func _pressed() -> void:
	lander_pressed.emit(_lander)
	var type := Action.Type.ATTACK if _display_state == DisplayState.ENEMY else Action.Type.MOVE_UNITS
	action_requested.emit(Action.create(type))


#region Accessors
func get_lander() -> Lander:
	return _lander


func set_lander(value: Lander) -> void:
	_lander = value
	_refresh()


func get_display_state() -> DisplayState:
	return _display_state


func set_display_state(value: DisplayState) -> void:
	_display_state = value
	_refresh()
#endregion


#region Private
func _refresh() -> void:
	if _lander != null:
		text = _lander.get_biome_data().get_display_name()
		icon = _lander.get_biome_data().get_icon()
	match _display_state:
		DisplayState.ALLY:
			add_theme_stylebox_override("normal", STYLE_ALLY)
		DisplayState.ENEMY:
			add_theme_stylebox_override("normal", STYLE_ENEMY)
		_:
			add_theme_stylebox_override("normal", STYLE_DEFAULT)
#endregion
