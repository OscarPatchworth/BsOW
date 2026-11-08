# move_dialog.gd
class_name MoveDialog
extends PanelContainer

## Choose which units move from one lander to a connected one. Opens with all but one unit
## selected (so the lander you leave stays yours). When the target is an undefended enemy
## lander with a building, the confirm button becomes "Capture" / "Raze".

signal action_requested(action: Action)

var _player: Player
var _from: Lander
var _to: Lander
var _unit_buttons: Array[Button] = []

var _title: Label
var _units_box: GridContainer
var _note: Label
var _confirm_row: HBoxContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(520, 0)
	add_theme_stylebox_override("panel", HudTheme.panel_style(HudTheme.BACKGROUND_SOLID, 10, 16))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_title = HudTheme.make_label("", HudTheme.TITLE_FONT_SIZE)
	box.add_child(_title)

	var quick := HBoxContainer.new()
	quick.add_child(HudTheme.make_label("Units to move:", HudTheme.FONT_SIZE, HudTheme.MUTED))
	var all_button := HudTheme.make_button("All")
	all_button.pressed.connect(func() -> void: _set_all(true))
	var none_button := HudTheme.make_button("None")
	none_button.pressed.connect(func() -> void: _set_all(false))
	quick.add_child(all_button)
	quick.add_child(none_button)
	box.add_child(quick)

	_units_box = GridContainer.new()
	_units_box.columns = 2
	box.add_child(_units_box)
	_note = HudTheme.make_label("", HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_note)

	_confirm_row = HBoxContainer.new()
	_confirm_row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(_confirm_row)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("esc"):
		close()
		get_viewport().set_input_as_handled()


#region Public API
func bind_player(player: Player) -> void:
	_player = player


## `select_all` = start with every unit selected (e.g. moving in after a won battle).
func open(from: Lander, to: Lander, select_all: bool = false) -> void:
	_from = from
	_to = to
	_title.text = "Move units: %s → %s" % [EventLog.lander_name(from), EventLog.lander_name(to)]
	HudTheme.clear_children(_units_box)
	_unit_buttons.clear()
	var units := from.get_units()
	for i in units.size():
		var button := HudTheme.make_button(units[i].get_display_name())
		button.toggle_mode = true
		button.button_pressed = select_all or units.size() == 1 or i < units.size() - 1
		button.set_meta(&"unit", units[i])
		button.toggled.connect(func(_on: bool) -> void: _refresh())
		_unit_buttons.append(button)
		_units_box.add_child(button)
	_build_confirm_buttons()
	show()
	_refresh()


func close() -> void:
	hide()
	_from = null
	_to = null
#endregion


#region Private
func _build_confirm_buttons() -> void:
	HudTheme.clear_children(_confirm_row)
	var cancel := HudTheme.make_button("Cancel")
	cancel.pressed.connect(close)
	_confirm_row.add_child(cancel)

	if _is_undefended_enemy_building() and _to.get_building().is_command_tower():
		var tower_owner := _to.get_building().get_owner_actor()
		var raze_tower := HudTheme.make_button("Move in & raze their command tower", true)
		raze_tower.tooltip_text = "%s is knocked out of the game" % tower_owner.get_display_name()
		raze_tower.pressed.connect(_submit.bind(Action.BuildingFate.RAZE))
		_confirm_row.add_child(raze_tower)
	elif _is_undefended_enemy_building():
		var building_name := _to.get_building().get_display_name()
		var capture := HudTheme.make_button("Move in & capture %s" % building_name, true)
		capture.tooltip_text = "The building becomes yours"
		capture.pressed.connect(_submit.bind(Action.BuildingFate.CAPTURE))
		var raze := HudTheme.make_button("Move in & raze %s" % building_name, true)
		raze.tooltip_text = "The building is destroyed"
		raze.pressed.connect(_submit.bind(Action.BuildingFate.RAZE))
		_confirm_row.add_child(capture)
		_confirm_row.add_child(raze)
	else:
		var move := HudTheme.make_button("Move", true)
		move.name = "MoveButton"
		move.pressed.connect(_submit.bind(Action.BuildingFate.NONE))
		_confirm_row.add_child(move)


func _refresh() -> void:
	var chosen := _chosen_units().size()
	var room := _to.get_unit_capacity() - _to.get_units().size()
	var notes: Array[String] = []
	if _is_undefended_enemy_building():
		notes.append("%s's %s has no defenders: take it by moving in." % [
			_to.get_building().get_owner_actor().get_display_name(), _to.get_building().get_display_name()])
	if chosen == _from.get_units().size() and not _from.has_building():
		notes.append("Moving every unit leaves %s unclaimed." % EventLog.lander_name(_from))
	if chosen > room:
		notes.append("Only %d more unit%s fit there." % [room, "" if room == 1 else "s"])
	_note.text = "\n".join(notes)
	_note.add_theme_color_override("font_color", HudTheme.WARN if chosen > room else HudTheme.MUTED)
	for button in _confirm_row.get_children():
		if button is Button and button.text != "Cancel":
			(button as Button).disabled = chosen == 0 or chosen > room


func _chosen_units() -> Array[UnitInstance]:
	var chosen: Array[UnitInstance] = []
	for button in _unit_buttons:
		if button.button_pressed:
			chosen.append(button.get_meta(&"unit"))
	return chosen


func _set_all(is_on: bool) -> void:
	for button in _unit_buttons:
		button.set_pressed_no_signal(is_on)
	_refresh()


func _is_undefended_enemy_building() -> bool:
	return _to.has_building() and not _to.has_units() and _to.get_building().get_owner_actor() != _player


func _submit(fate: Action.BuildingFate) -> void:
	var action := Action.create(Action.Type.MOVE_UNITS)
	action.set_source_lander(_from)
	action.set_target_lander(_to)
	action.set_units(_chosen_units())
	action.set_building_fate(fate)
	action_requested.emit(action)
	close()
#endregion
