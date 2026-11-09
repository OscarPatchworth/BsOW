# phase_hint.gd
class_name PhaseHint
extends PanelContainer

## One line under the top bar saying what to do right now. flash_problem() briefly shows why
## something was refused.

const PROBLEM_SECONDS: float = 3.5

var _label: Label
var _hint := ""
var _problem_tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", HudTheme.panel_style(HudTheme.BACKGROUND, 8, 9))
	_label = HudTheme.make_label("", HudTheme.FONT_SIZE)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


func set_hint(text: String, color: Color = HudTheme.TEXT) -> void:
	_hint = text
	if _problem_tween != null and _problem_tween.is_running():
		return  # The problem message is showing; the hint returns after it.
	_show(text, color)


## Shows `reason` in red for a few seconds, then goes back to the hint.
func flash_problem(reason: String) -> void:
	_flash("✗  " + reason, HudTheme.BAD)


## Shows `text` (e.g. "SimpleAI is attacking your Plains lander!") for a few seconds.
func flash_alert(text: String, color: Color = HudTheme.WARN) -> void:
	_flash(text, color)


func _flash(text: String, color: Color) -> void:
	_show(text, color)
	if _problem_tween != null:
		_problem_tween.kill()
	_problem_tween = create_tween()
	_problem_tween.tween_interval(PROBLEM_SECONDS)
	_problem_tween.tween_callback(func() -> void: _show(_hint, HudTheme.TEXT))


func _show(text: String, color: Color) -> void:
	_label.text = text
	_label.add_theme_color_override("font_color", color)
	visible = text != ""
