# battle_dialog.gd
class_name BattleDialog
extends PanelContainer

## The battle window. It stays open for the whole battle (every round):
##   your units (toggle to pick who fights; your strongest are picked when it opens),
##   the opponent's units and whether they're ready, the dice of the last round,
##   and Fight / Retreat. When the battle ends it shows the result, plus "Move in" if you won
##   as the attacker, and Close.

signal action_requested(action: Action)
signal move_in_requested(from: Lander, to: Lander)
signal closed()

var _player: Player
var _combat_manager: CombatManager
var _contest: Contest

var _title: Label
var _subtitle: Label
var _our_header: Label
var _our_units: GridContainer
var _their_header: Label
var _their_units: VBoxContainer
var _results: VBoxContainer
var _result_banner: Label
var _buttons: HBoxContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(760, 0)
	add_theme_stylebox_override("panel", HudTheme.panel_style(HudTheme.BACKGROUND_SOLID, 12, 18))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_title = HudTheme.make_label("", HudTheme.TITLE_FONT_SIZE + 4)
	box.add_child(_title)
	_subtitle = HudTheme.make_label("", HudTheme.FONT_SIZE, HudTheme.MUTED)
	box.add_child(_subtitle)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	var ours := VBoxContainer.new()
	ours.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_our_header = HudTheme.make_label()
	ours.add_child(_our_header)
	_our_units = GridContainer.new()
	_our_units.columns = 2
	ours.add_child(_our_units)
	columns.add_child(ours)
	var theirs := VBoxContainer.new()
	theirs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_their_header = HudTheme.make_label()
	theirs.add_child(_their_header)
	_their_units = VBoxContainer.new()
	theirs.add_child(_their_units)
	columns.add_child(theirs)
	box.add_child(columns)

	box.add_child(HSeparator.new())
	_results = VBoxContainer.new()
	_results.add_theme_constant_override("separation", 2)
	box.add_child(_results)
	_result_banner = HudTheme.make_label("", HudTheme.TITLE_FONT_SIZE)
	_result_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_banner)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(_buttons)
	hide()


#region Public API
func bind(player: Player, combat_manager: CombatManager) -> void:
	_player = player
	_combat_manager = combat_manager


## A battle the player is part of has started.
func open(contest: Contest) -> void:
	_contest = contest
	show()
	_preselect_strongest()
	refresh()


func refresh() -> void:
	if _contest == null or not visible:
		return
	var our_side := _contest.get_side_of(_player)
	var their_side := Contest.get_opposite_side(our_side)
	var opponent := _contest.get_actor(their_side)
	var target := EventLog.lander_name(_contest.get_lander(Contest.Side.DEFENDER))
	_title.text = "⚔  Battle · Round %d" % _contest.get_round()
	if our_side == Contest.Side.ATTACKER:
		_subtitle.text = "You attack %s's %s lander" % [HudTheme.actor_name(opponent), target]
	else:
		_subtitle.text = "%s attacks your %s lander!" % [HudTheme.actor_name(opponent), target]
	_refresh_our_units(our_side)
	_refresh_their_units(their_side, opponent)
	_refresh_buttons(our_side)


## Shows the dice of the round that just finished.
func show_round(outcomes: Array[CombatOutcome]) -> void:
	HudTheme.clear_children(_results)
	if _contest == null:
		return
	var our_actor := _player
	var ours: Array[CombatOutcome] = []
	var theirs: Array[CombatOutcome] = []
	for outcome in outcomes:
		(ours if outcome.get_unit().get_owner_actor() == our_actor else theirs).append(outcome)
	_results.add_child(HudTheme.make_label("Round %d results" % (_contest.get_round() - (0 if _contest.is_over() else 1)),
		HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED))
	for i in maxi(ours.size(), theirs.size()):
		var line := ""
		var color := HudTheme.TEXT
		if i < ours.size() and i < theirs.size():
			var we_won := ours[i].get_outcome() == CombatOutcome.Outcome.ALIVE
			line = "%s  %s   vs   %s  %s   →  %s" % [ours[i].get_unit().get_display_name(), _roll_text(ours[i]),
				_roll_text(theirs[i]), theirs[i].get_unit().get_display_name(), "you win" if we_won else "you lose"]
			color = HudTheme.GOOD if we_won else HudTheme.BAD
		elif i < ours.size():
			line = "%s  %s   (no opponent)" % [ours[i].get_unit().get_display_name(), _roll_text(ours[i])]
		else:
			line = "(no opponent)   %s  %s" % [_roll_text(theirs[i]), theirs[i].get_unit().get_display_name()]
		_results.add_child(HudTheme.make_label(line, HudTheme.FONT_SIZE, color))
	refresh()


func show_ended(contest: Contest) -> void:
	_contest = contest
	refresh()


func get_contest() -> Contest:
	return _contest


func close() -> void:
	hide()
	_contest = null
	HudTheme.clear_children(_results)
	closed.emit()
#endregion


#region Private
func _refresh_our_units(our_side: int) -> void:
	HudTheme.clear_children(_our_units)
	var available := _contest.get_available_units(our_side)
	var selected := _contest.get_units(our_side)
	var max_units := _combat_manager.get_max_units(our_side)
	_our_header.text = "You (%s) · %d units · fighting %d/%d" % [
		"attacking" if our_side == Contest.Side.ATTACKER else "defending", available.size(), selected.size(), max_units]
	_our_header.add_theme_color_override("font_color", _player.get_color().lightened(0.3))
	var is_locked := _contest.is_over() or _contest.is_ready(our_side)
	for unit in available:
		var button := HudTheme.make_button("%s  %s" % [unit.get_display_name(), LanderInspector._dice_text(unit.get_damage())])
		button.toggle_mode = true
		button.button_pressed = unit in selected
		button.disabled = is_locked or (unit not in selected and selected.size() >= max_units)
		button.tooltip_text = "Pick who fights this round" if not is_locked else ""
		button.toggled.connect(_on_unit_toggled.bind(unit))
		_our_units.add_child(button)


func _refresh_their_units(their_side: int, opponent: Actor) -> void:
	HudTheme.clear_children(_their_units)
	var available := _contest.get_available_units(their_side)
	var selected := _contest.get_units(their_side)
	var status := "ready" if _contest.is_ready(their_side) else "choosing…"
	_their_header.text = "%s · %d units · %s" % [HudTheme.actor_name(opponent), available.size(), status]
	_their_header.add_theme_color_override("font_color", HudTheme.actor_color(opponent).lightened(0.3))
	for unit in available:
		var is_fighting := unit in selected
		_their_units.add_child(HudTheme.make_label("%s %s  %s" % ["⚔" if is_fighting else "  ", unit.get_display_name(),
			LanderInspector._dice_text(unit.get_damage())], HudTheme.FONT_SIZE, HudTheme.TEXT if is_fighting else HudTheme.MUTED))


func _refresh_buttons(our_side: int) -> void:
	HudTheme.clear_children(_buttons)
	if _contest.is_over():
		_result_banner.text = _result_text(our_side)
		_result_banner.visible = true
		_result_banner.add_theme_color_override("font_color", _result_color(our_side))
		var survivors := _contest.get_available_units(our_side)
		if (our_side == Contest.Side.ATTACKER and _contest.get_result() == Contest.Result.ATTACKER_WON
				and not survivors.is_empty()):
			var move_in := HudTheme.make_button("Move in  ▸", true)
			move_in.tooltip_text = "Move your survivors onto the defeated lander"
			move_in.pressed.connect(_on_move_in_pressed)
			_buttons.add_child(move_in)
		var close_button := HudTheme.make_button("Close")
		close_button.pressed.connect(close)
		_buttons.add_child(close_button)
		return

	_result_banner.visible = false
	if our_side == Contest.Side.ATTACKER:
		var retreat := HudTheme.make_button("Retreat")
		retreat.tooltip_text = "Call the battle off; everyone stays where they are"
		retreat.pressed.connect(_request.bind(Action.Type.RETREAT_COMBAT))
		_buttons.add_child(retreat)
	if _contest.is_ready(our_side):
		var change := HudTheme.make_button("Change units")
		change.pressed.connect(_request.bind(Action.Type.WITHDRAW_COMBAT_READY))
		_buttons.add_child(change)
		var waiting := HudTheme.make_button("Waiting for %s…" % HudTheme.actor_name(_contest.get_actor(Contest.get_opposite_side(our_side))))
		waiting.disabled = true
		_buttons.add_child(waiting)
	else:
		var fight := HudTheme.make_button("Fight!", true)
		fight.name = "FightButton"
		fight.disabled = _contest.get_units(our_side).is_empty()
		fight.tooltip_text = "Pick at least one unit first" if fight.disabled else "Roll the dice"
		fight.pressed.connect(_request.bind(Action.Type.DECLARE_COMBAT_READY))
		_buttons.add_child(fight)


func _result_text(our_side: int) -> String:
	match _contest.get_result():
		Contest.Result.ATTACKER_WON:
			return "Victory! The defenders are wiped out." if our_side == Contest.Side.ATTACKER else "Defeat. Your defenders were wiped out."
		Contest.Result.DEFENDER_WON:
			return "Victory! The attack was beaten off." if our_side == Contest.Side.DEFENDER else "Defeat. Your attackers were wiped out."
		Contest.Result.RETREATED:
			return "The attacker retreated."
		Contest.Result.STALEMATE:
			return "Stalemate: nobody broke through."
	return ""


func _result_color(our_side: int) -> Color:
	var result := _contest.get_result()
	var we_won := (result == Contest.Result.ATTACKER_WON and our_side == Contest.Side.ATTACKER) \
		or (result == Contest.Result.DEFENDER_WON and our_side == Contest.Side.DEFENDER)
	if result in [Contest.Result.RETREATED, Contest.Result.STALEMATE]:
		return HudTheme.WARN
	return HudTheme.GOOD if we_won else HudTheme.BAD


## Opening a battle picks our strongest units for us (we can still change them).
func _preselect_strongest() -> void:
	var our_side := _contest.get_side_of(_player)
	if not _contest.get_units(our_side).is_empty():
		return
	var available := _contest.get_available_units(our_side).duplicate()
	available.sort_custom(func(a: UnitInstance, b: UnitInstance) -> bool:
		return _strength(a.get_damage()) > _strength(b.get_damage()))
	for i in mini(available.size(), _combat_manager.get_max_units(our_side)):
		var select := Action.create(Action.Type.SELECT_COMBAT_UNIT)
		select.set_units([available[i]] as Array[UnitInstance])
		action_requested.emit(select)


func _on_unit_toggled(is_on: bool, unit: UnitInstance) -> void:
	var action := Action.create(Action.Type.SELECT_COMBAT_UNIT if is_on else Action.Type.DESELECT_COMBAT_UNIT)
	action.set_units([unit] as Array[UnitInstance])
	action_requested.emit(action)


func _request(type: Action.Type) -> void:
	action_requested.emit(Action.create(type))


func _on_move_in_pressed() -> void:
	var from := _contest.get_lander(Contest.Side.ATTACKER)
	var to := _contest.get_lander(Contest.Side.DEFENDER)
	close()
	move_in_requested.emit(from, to)


static func _roll_text(outcome: CombatOutcome) -> String:
	return "🎲%d" % outcome.get_total()


static func _strength(damage: DamageData) -> float:
	if damage == null:
		return 0.0
	return damage.get_dice_count() * (damage.get_dice_sides() + 1) / 2.0 + damage.get_modifier()
#endregion
