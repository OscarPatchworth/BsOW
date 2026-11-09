# event_log.gd
class_name EventLog
extends PanelContainer

## A short running log of what happened ("SimpleAI attacks your Plains lander!"), newest at the
## bottom. Older lines fade. describe() turns a resolved Action into a line (or "" to skip it).

const MAX_LINES: int = 9
const WIDTH: float = 460.0

var _lines: VBoxContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(WIDTH, 0)
	var box := VBoxContainer.new()
	box.add_child(HudTheme.make_label("Log", HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED))
	_lines = VBoxContainer.new()
	_lines.add_theme_constant_override("separation", 2)
	box.add_child(_lines)
	add_child(box)


## `bbcode` may use [color] tags (see actor_tag()).
func add_line(bbcode: String, color: Color = HudTheme.TEXT) -> void:
	if bbcode == "":
		return
	var line := RichTextLabel.new()
	line.bbcode_enabled = true
	line.fit_content = true
	line.scroll_active = false
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# A known wrap width: otherwise the first layout wraps at width 0 and the panel grows huge.
	line.custom_minimum_size.x = WIDTH - 26
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_font_size_override("normal_font_size", HudTheme.SMALL_FONT_SIZE + 1)
	line.add_theme_color_override("default_color", color)
	line.text = bbcode
	_lines.add_child(line)
	while _lines.get_child_count() > MAX_LINES:
		_lines.get_child(0).free()
	for i in _lines.get_child_count():
		var age := _lines.get_child_count() - 1 - i
		(_lines.get_child(i) as CanvasItem).modulate.a = clampf(1.0 - age * 0.09, 0.35, 1.0)


static func actor_tag(actor: Actor) -> String:
	if actor == null:
		return "Nobody"
	return "[color=#%s]%s[/color]" % [actor.get_color().lightened(0.3).to_html(false), actor.get_display_name()]


static func lander_name(lander: Lander) -> String:
	if lander == null or lander.get_biome_data() == null:
		return "a lander"
	return lander.get_biome_data().get_display_name()


## One log line for a resolved action, or "" for actions not worth a line.
static func describe(action: Action, viewer: Actor) -> String:
	var who := actor_tag(action.get_actor())
	match action.get_type():
		Action.Type.PLACE_BIOME:
			return "%s placed a %s lander" % [who, action.get_biome_data().get_display_name()]
		Action.Type.PLACE_BUILDING:
			return "%s built %s %s" % [who, "your" if action.get_actor() == viewer else "their",
				action.get_building_data().get_display_name()]
		Action.Type.PLACE_LANDER:
			return "%s dropped a lander out of the dust cloud" % who
		Action.Type.PURCHASE:
			return "%s bought %s on %s" % [who, action.get_purchasable().get("display_name"), lander_name(action.get_target_lander())]
		Action.Type.MOVE_UNITS:
			var text := "%s moved %d unit%s to %s" % [who, action.get_units().size(),
				"" if action.get_units().size() == 1 else "s", lander_name(action.get_target_lander())]
			match action.get_building_fate():
				Action.BuildingFate.CAPTURE:
					text += " and captured the building"
				Action.BuildingFate.RAZE:
					text += " and razed the building"
			return text
		Action.Type.ATTACK:
			var defender := action.get_target_lander().get_owner_actor()
			var whose := "your" if defender == viewer else "%s's" % actor_tag(defender)
			return "⚔ %s attacked %s %s lander!" % [who, whose, lander_name(action.get_target_lander())]
		Action.Type.RETREAT_COMBAT:
			return "%s retreated" % who
	return ""
