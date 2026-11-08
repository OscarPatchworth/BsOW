# hud_theme.gd
class_name HudTheme
extends RefCounted

## The HUD's look in one place: colours, the Theme every HUD control uses, and small helpers
## for building labels, buttons and panels in code.

const BACKGROUND := Color(0.075, 0.085, 0.11, 0.88)
const BACKGROUND_SOLID := Color(0.09, 0.10, 0.13, 0.97)
const RAISED := Color(0.16, 0.18, 0.23, 1.0)
const BORDER := Color(1, 1, 1, 0.09)
const TEXT := Color(0.93, 0.94, 0.97)
const MUTED := Color(0.63, 0.66, 0.73)
const ACCENT := Color(0.38, 0.72, 1.0)
const GOOD := Color(0.42, 0.88, 0.55)
const BAD := Color(1.0, 0.45, 0.42)
const WARN := Color(1.0, 0.76, 0.32)

const FONT_SIZE: int = 17
const SMALL_FONT_SIZE: int = 14
const TITLE_FONT_SIZE: int = 22

## Emoji per EconData resource key (rendered by the system emoji font).
const RESOURCE_ICONS := {
	&"gold": 0x1FA99,
	&"food": 0x1F356,
	&"mineral": 0x1F48E,
	&"wood": 0x1FAB5,
	&"stone": 0x1FAA8,
}

static var _theme: Theme


## The shared Theme (built once).
static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build_theme()
	return _theme


static func panel_style(color: Color = BACKGROUND, radius: int = 8, padding: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	style.border_color = BORDER
	style.set_border_width_all(1)
	return style


static func make_label(text: String = "", font_size: int = FONT_SIZE, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


static func make_button(text: String, is_primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	if is_primary:
		button.add_theme_stylebox_override("normal", _button_style(ACCENT.darkened(0.35)))
		button.add_theme_stylebox_override("hover", _button_style(ACCENT.darkened(0.2)))
		button.add_theme_stylebox_override("pressed", _button_style(ACCENT.darkened(0.45)))
	return button


static func make_panel(color: Color = BACKGROUND) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style(color))
	return panel


## A small coloured square, e.g. an actor's colour.
static func make_swatch(color: Color, size: float = 14.0) -> ColorRect:
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(size, size)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return swatch


static func resource_icon(key: StringName) -> String:
	return char(RESOURCE_ICONS.get(key, 0x2022))


## "🪙1 🪵3 🪨2" for the non-zero amounts (or "free").
static func format_cost(econ: EconData) -> String:
	if econ == null:
		return "free"
	var parts: Array[String] = []
	for key in EconData.RESOURCE_KEYS:
		var amount := econ.get_amount(key)
		if amount != 0:
			parts.append("%s%d" % [resource_icon(key), amount])
	return " ".join(parts) if not parts.is_empty() else "free"


## "Lycanth Halfbreed" -> text, colour of the actor (or neutral).
static func actor_name(actor: Actor) -> String:
	return actor.get_display_name() if actor != null else "Nobody"


static func actor_color(actor: Actor) -> Color:
	return actor.get_color() if actor != null else Lander.NEUTRAL_COLOR


static func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


static func _build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	theme.set_color("font_color", "Label", TEXT)
	theme.set_stylebox("panel", "PanelContainer", panel_style())
	theme.set_stylebox("panel", "TooltipPanel", panel_style(BACKGROUND_SOLID, 6, 8))
	theme.set_color("font_color", "TooltipLabel", TEXT)

	theme.set_stylebox("normal", "Button", _button_style(RAISED))
	theme.set_stylebox("hover", "Button", _button_style(RAISED.lightened(0.12)))
	theme.set_stylebox("pressed", "Button", _button_style(ACCENT.darkened(0.3)))
	theme.set_stylebox("hover_pressed", "Button", _button_style(ACCENT.darkened(0.2)))
	theme.set_stylebox("disabled", "Button", _button_style(Color(RAISED, 0.5)))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color(MUTED, 0.6))

	theme.set_stylebox("separator", "HSeparator", _line_style())
	theme.set_constant("separation", "HSeparator", 10)
	theme.set_constant("separation", "VBoxContainer", 6)
	theme.set_constant("separation", "HBoxContainer", 8)
	return theme


static func _line_style() -> StyleBoxLine:
	var line := StyleBoxLine.new()
	line.color = BORDER
	line.thickness = 1
	return line
