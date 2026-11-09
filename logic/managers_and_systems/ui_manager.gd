# ui_manager.gd
class_name UiManager
extends Control

## Root of the player's HUD. Builds the panels (all in code, styled by HudTheme), hands them
## what they need, and turns game events into HUD updates. Requests leave as Actions through
## action_requested (the Player stamps itself on them).
##
## Layout:  TopBar (top) · PhaseHint (under it) · PlayersList (left) · LanderInspector (right)
##          EventLog (bottom left) · SetupPanel (bottom centre) · MoveDialog / BattleDialog (centre)
##
## The root ignores the mouse, so clicks on empty screen reach the board; panels stop them.

signal action_requested(action: Action)
signal setup_biome_selected(biome_data: BiomeData)
signal all_setup_biomes_placed()
signal camera_focus_requested(point: Vector3)

const MARGIN: float = 12.0
const SIDE_PANEL_TOP: float = 130.0

## Where a panel is pinned. Passed around as int: Godot 4.7 can mis-resolve the enum type
## through cyclic class references (same as Contest.Side).
enum Corner { TOP_WIDE, TOP_CENTER, TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_CENTER, CENTER }

var _player: Player
var _turn_manager: TurnManager
var _lander_manager: LanderManager
var _combat_manager: CombatManager
var _match_settings: MatchSettings
var _selector_manager: SelectorManager

var _top_bar := TopBar.new()
var _hint := PhaseHint.new()
var _players_list := PlayersList.new()
var _inspector := LanderInspector.new()
var _event_log := EventLog.new()
var _setup_panel := SetupPanel.new()
var _move_dialog := MoveDialog.new()
var _battle_dialog := BattleDialog.new()
var _game_over_panel := GameOverPanel.new()
## Control -> Corner, re-applied by _relayout() when panel contents change size.
var _placements := {}
var _is_relayout_queued: bool = false


func _ready() -> void:
	theme = HudTheme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar.name = "TopBar"
	_setup_panel.name = "SetupPanel"
	_inspector.name = "LanderInspector"
	_move_dialog.name = "MoveDialog"
	_battle_dialog.name = "BattleDialog"
	_place(_top_bar, Corner.TOP_WIDE)
	_place(_hint, Corner.TOP_CENTER)
	_place(_players_list, Corner.TOP_LEFT)
	_place(_inspector, Corner.TOP_RIGHT)
	_place(_event_log, Corner.BOTTOM_LEFT)
	_place(_setup_panel, Corner.BOTTOM_CENTER)
	_place(_move_dialog, Corner.CENTER)
	_place(_battle_dialog, Corner.CENTER)
	_place(_game_over_panel, Corner.CENTER)
	_game_over_panel.name = "GameOverPanel"
	_players_list.hide()
	_hint.hide()
	_connect_panels()
	get_viewport().size_changed.connect(_queue_relayout)


#region Binding
func bind_player(player: Player) -> void:
	_player = player
	_move_dialog.bind_player(player)


func bind_selector_manager(selector_manager: SelectorManager) -> void:
	_selector_manager = selector_manager


func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager


func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_manager = lander_manager


func bind_combat_manager(combat_manager: CombatManager) -> void:
	_combat_manager = combat_manager


func bind_match_settings(match_settings: MatchSettings) -> void:
	_match_settings = match_settings


## Called once everything is bound (Player._bind_children).
func finish_binding() -> void:
	_top_bar.bind(_player, _turn_manager, _lander_manager, _match_settings, _combat_manager)
	_players_list.bind(_turn_manager, _lander_manager)
	_inspector.bind(_player, _turn_manager, _lander_manager, _combat_manager)
	_setup_panel.bind(_player, _match_settings)
	_battle_dialog.bind(_player, _combat_manager)
#endregion


#region Public API (called by the Player)
func show_lander_panel(lander: Lander) -> void:
	_inspector.show_lander(lander)
	_queue_relayout()


func refresh_lander_panel() -> void:
	_inspector.refresh()
	_queue_relayout()


func show_movement_panel(from_lander: Lander, to_lander: Lander, select_all: bool = false) -> void:
	_move_dialog.open(from_lander, to_lander, select_all)
	_queue_relayout()


func show_combat(contest: Contest) -> void:
	_move_dialog.close()
	_battle_dialog.open(contest)
	camera_focus_requested.emit(contest.get_lander(Contest.Side.DEFENDER).get_board_position())
	_refresh_all()


func update_combat(_contest: Contest) -> void:
	_battle_dialog.refresh()
	_refresh_all()


func show_combat_outcome(outcomes: Array[CombatOutcome]) -> void:
	_battle_dialog.show_round(outcomes)
	_log_round(outcomes)
	_refresh_all()


func show_combat_ended(contest: Contest) -> void:
	_battle_dialog.show_ended(contest)
	_event_log.add_line(_battle_summary(contest), HudTheme.WARN)
	_refresh_all()


func apply_game_state(state: TurnManager.GameState) -> void:
	if state == TurnManager.GameState.SETUP:
		_setup_panel.begin()
		_event_log.add_line("You are the [color=#%s]%s[/color]. Place your starting landers." % [
			_player.get_color().lightened(0.3).to_html(false), _player.get_species().get_display_name()])
	elif state == TurnManager.GameState.MAIN_LOOP:
		_setup_panel.hide()
		_players_list.show()
		_event_log.add_line("The game begins!", HudTheme.ACCENT)
		var home := _lander_manager.get_landers_owned_by(_player)
		if not home.is_empty():
			camera_focus_requested.emit(home[0].get_board_position())
	_refresh_all()


func apply_game_phase(_phase: TurnManager.Phase) -> void:
	_refresh_all()


func apply_active_actor(active_actor: Actor) -> void:
	if _turn_manager.get_game_state() == TurnManager.GameState.MAIN_LOOP:
		_event_log.add_line("— %s turn (round %d) —" % [
			"Your" if active_actor == _player else EventLog.actor_tag(active_actor) + "'s", _turn_manager.get_round_number()],
			HudTheme.MUTED)
	_refresh_all()


func apply_season(_season_index: int) -> void:
	_event_log.add_line("A new season: %s" % TurnManager.Season.find_key(_turn_manager.get_current_season()).capitalize(),
		HudTheme.MUTED)
	_refresh_all()


func show_turn_order() -> void:
	_refresh_all()


func show_seasons() -> void:
	_refresh_all()


func on_setup_biome_placed(action: Action) -> void:
	_setup_panel.on_biome_placed(action)
	_refresh_all()


func on_wallet_changed() -> void:
	_top_bar.refresh()


func on_units_moved() -> void:
	refresh_lander_panel()


## Any resolved action (by anyone): log it and refresh what might have changed.
func on_action_resolved(action: Action) -> void:
	if not action.is_system():
		_event_log.add_line(EventLog.describe(action, _player))
	if action.get_type() == Action.Type.COLLECT_UPKEEP and action.get_actor() == _player:
		_event_log.add_line("You collected your upkeep", HudTheme.MUTED)
	_refresh_all()


## One of the player's own actions was refused: say why.
func on_action_rejected(_action: Action, reason: String) -> void:
	_hint.flash_problem(reason)
	_event_log.add_line("✗ " + reason, HudTheme.BAD)
	_queue_relayout()


func on_actor_eliminated(actor: Actor) -> void:
	_event_log.add_line("☠ %s lost their command tower and is out of the game!" % EventLog.actor_tag(actor), HudTheme.WARN)
	_refresh_all()


func show_game_over(winner: Actor) -> void:
	_move_dialog.close()
	if _battle_dialog.visible:
		_battle_dialog.close()
	_game_over_panel.open(winner, _player)
	var result_text := "Game over"
	if winner == _player:
		result_text = "Game over: you win!"
	elif winner != null:
		result_text = "Game over: %s wins!" % EventLog.actor_tag(winner)
	_event_log.add_line(result_text, HudTheme.ACCENT)
	_refresh_all()


func get_game_over_panel() -> GameOverPanel:
	return _game_over_panel


func get_setup_panel() -> SetupPanel:
	return _setup_panel


func get_inspector() -> LanderInspector:
	return _inspector


func get_battle_dialog() -> BattleDialog:
	return _battle_dialog


func get_move_dialog() -> MoveDialog:
	return _move_dialog
#endregion


#region Private
func _connect_panels() -> void:
	_top_bar.action_requested.connect(action_requested.emit)
	_inspector.action_requested.connect(action_requested.emit)
	_move_dialog.action_requested.connect(action_requested.emit)
	_battle_dialog.action_requested.connect(action_requested.emit)
	_battle_dialog.move_in_requested.connect(func(from: Lander, to: Lander) -> void:
		show_movement_panel(from, to, true))
	_battle_dialog.closed.connect(_queue_relayout)
	_setup_panel.biome_selected.connect(setup_biome_selected.emit)
	_setup_panel.all_biomes_placed.connect(func() -> void:
		all_setup_biomes_placed.emit()
		_refresh_all())


func _refresh_all() -> void:
	if _player == null or _turn_manager == null:
		return
	_top_bar.refresh()
	_players_list.refresh()
	_inspector.refresh()
	_battle_dialog.refresh()
	_refresh_hint()
	_queue_relayout()


func _refresh_hint() -> void:
	_hint.set_hint(_hint_text())


func _hint_text() -> String:
	if _turn_manager.get_game_state() == TurnManager.GameState.END:
		var winner := _turn_manager.get_winner()
		return "Game over: %s." % ("you win" if winner == _player else "%s wins" % HudTheme.actor_name(winner))
	if _turn_manager.get_game_state() == TurnManager.GameState.SETUP:
		if not _lander_manager.get_landers_owned_by(_player).is_empty():
			return "Setup done: waiting for everyone else to finish theirs…"
		if _setup_panel.get_remaining_biomes().is_empty():
			return "Setup: click one of your new landers to build your command tower on it."
		return "Setup: pick a biome below, then click open ground to drop it. The ghost shows where gravity will pull it."
	var active := _turn_manager.get_active_actor()
	if _combat_manager.is_in_progress() and _combat_manager.get_contest().is_involved(_player):
		return "Battle! Pick which units fight and press Fight. Survivors stay picked for the next round."
	if active != _player:
		return "%s is taking their turn…" % HudTheme.actor_name(active)
	match _turn_manager.get_game_phase():
		TurnManager.Phase.DUSTCLOUD_COLLAPSE:
			var next_biome := _lander_manager.peek_next_biome(_player)
			return "Dustcloud collapse: your next lander is %s (%s per turn). Click open ground to drop it (required). The ring shows where gravity pulls it." % [
				next_biome.get_display_name().to_upper(), HudTheme.format_yield(next_biome.get_upkeep())]
		TurnManager.Phase.BUYING:
			return "Buying: click one of your landers to train units or build. Press End buying when done."
		TurnManager.Phase.COMBAT:
			return "Combat: drag from your lander to a connected one. Gold arrow = move, red = attack, orange = take an undefended building. End turn when done."
	return ""


func _log_round(outcomes: Array[CombatOutcome]) -> void:
	var lost := {}
	for outcome in outcomes:
		if outcome.get_outcome() == CombatOutcome.Outcome.DEAD:
			var unit_owner := outcome.get_unit().get_owner_actor()
			lost[unit_owner] = lost.get(unit_owner, 0) + 1
	var contest := _combat_manager.get_contest()
	var attacker := contest.get_actor(Contest.Side.ATTACKER)
	var defender := contest.get_actor(Contest.Side.DEFENDER)
	_event_log.add_line("   Round result: %s lost %d, %s lost %d" % [EventLog.actor_tag(attacker), lost.get(attacker, 0),
		EventLog.actor_tag(defender), lost.get(defender, 0)], HudTheme.MUTED)


func _battle_summary(contest: Contest) -> String:
	var attacker := EventLog.actor_tag(contest.get_actor(Contest.Side.ATTACKER))
	var defender := EventLog.actor_tag(contest.get_actor(Contest.Side.DEFENDER))
	match contest.get_result():
		Contest.Result.ATTACKER_WON:
			return "Battle over: %s wiped out %s's defenders" % [attacker, defender]
		Contest.Result.DEFENDER_WON:
			return "Battle over: %s held off %s" % [defender, attacker]
		Contest.Result.RETREATED:
			return "Battle over: %s retreated" % attacker
		Contest.Result.STALEMATE:
			return "Battle over: stalemate"
	return ""


func _place(control: Control, corner: int) -> void:
	add_child(control)
	_placements[control] = corner
	_apply_placement(control, corner)


func _queue_relayout() -> void:
	if not _is_relayout_queued:
		_is_relayout_queued = true
		_relayout.call_deferred()


## Content-sized panels don't shrink by themselves; re-anchoring sizes them to their content again.
func _relayout() -> void:
	_is_relayout_queued = false
	for control: Control in _placements:
		_apply_placement(control, _placements[control])


func _apply_placement(control: Control, corner: int) -> void:
	control.size = Vector2.ZERO
	match corner:
		Corner.TOP_WIDE:
			control.set_anchors_preset(Control.PRESET_TOP_WIDE)
			control.offset_left = MARGIN
			control.offset_right = -MARGIN
			control.offset_top = MARGIN
			control.offset_bottom = MARGIN
		Corner.TOP_CENTER:
			control.set_anchors_preset(Control.PRESET_CENTER_TOP)
			control.grow_horizontal = Control.GROW_DIRECTION_BOTH
			_set_point(control, 0, MARGIN + 76)
		Corner.TOP_LEFT:
			control.set_anchors_preset(Control.PRESET_TOP_LEFT)
			_set_point(control, MARGIN, SIDE_PANEL_TOP)
		Corner.TOP_RIGHT:
			control.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			control.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			_set_point(control, -MARGIN, SIDE_PANEL_TOP)
		Corner.BOTTOM_LEFT:
			control.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			control.grow_vertical = Control.GROW_DIRECTION_BEGIN
			_set_point(control, MARGIN, -MARGIN)
		Corner.BOTTOM_CENTER:
			control.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			control.grow_horizontal = Control.GROW_DIRECTION_BOTH
			control.grow_vertical = Control.GROW_DIRECTION_BEGIN
			_set_point(control, 0, -MARGIN - 6)
		Corner.CENTER:
			control.set_anchors_preset(Control.PRESET_CENTER)
			control.grow_horizontal = Control.GROW_DIRECTION_BOTH
			control.grow_vertical = Control.GROW_DIRECTION_BOTH
			_set_point(control, 0, 40)


## Collapses the control to a point at the anchor (+offset); it then grows to its minimum size.
func _set_point(control: Control, x: float, y: float) -> void:
	control.offset_left = x
	control.offset_right = x
	control.offset_top = y
	control.offset_bottom = y
#endregion
