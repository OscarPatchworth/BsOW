# players_list.gd
class_name PlayersList
extends PanelContainer

## Everyone in turn order: colour, name, race, landers and units. The active actor is marked.

var _turn_manager: TurnManager
var _lander_manager: LanderManager
var _rows: VBoxContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var box := VBoxContainer.new()
	box.add_child(HudTheme.make_label("Players", HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	box.add_child(_rows)
	add_child(box)


func bind(turn_manager: TurnManager, lander_manager: LanderManager) -> void:
	_turn_manager = turn_manager
	_lander_manager = lander_manager


func refresh() -> void:
	if _turn_manager == null:
		return
	for child in _rows.get_children():
		child.free()
	var active := _turn_manager.get_active_actor()
	var is_main_loop := _turn_manager.get_game_state() == TurnManager.GameState.MAIN_LOOP
	for actor in _turn_manager.get_turn_order():
		var landers := _lander_manager.get_landers_owned_by(actor)
		var unit_count := 0
		for lander in landers:
			unit_count += lander.get_units().size()

		var row := HBoxContainer.new()
		var marker := HudTheme.make_label("▶" if actor == active and is_main_loop else " ", HudTheme.FONT_SIZE, actor.get_color())
		marker.custom_minimum_size.x = 16
		row.add_child(marker)
		row.add_child(HudTheme.make_swatch(actor.get_color()))
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 0)
		text.add_child(HudTheme.make_label("%s · %s" % [actor.get_display_name(), actor.get_species().get_display_name()],
			HudTheme.FONT_SIZE, actor.get_color().lightened(0.3)))
		text.add_child(HudTheme.make_label("%d landers · %d units" % [landers.size(), unit_count],
			HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED))
		row.add_child(text)
		_rows.add_child(row)
