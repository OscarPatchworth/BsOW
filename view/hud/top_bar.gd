# top_bar.gd
class_name TopBar
extends PanelContainer

## The strip along the top of the screen:
##   [you: colour, name, race] [wallet (+ next turn's income)] [round · season] [phase track] [turn] [next step]
## The "next step" button says what it does (End buying, End turn, ...) and is only enabled when
## pressing it is allowed.

signal action_requested(action: Action)

var _player: Player
var _turn_manager: TurnManager
var _lander_manager: LanderManager
var _match_settings: MatchSettings
var _combat_manager: CombatManager

var _identity_swatch: ColorRect
var _identity_label: Label
var _wallet_labels := {}
var _round_label: Label
var _phase_labels: Array[Label] = []
var _turn_label: Label
var _next_button: Button


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", HudTheme.panel_style(HudTheme.BACKGROUND, 10, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	add_child(row)

	var identity := HBoxContainer.new()
	_identity_swatch = HudTheme.make_swatch(Color.WHITE, 18)
	_identity_label = HudTheme.make_label("", HudTheme.TITLE_FONT_SIZE)
	identity.add_child(_identity_swatch)
	identity.add_child(_identity_label)
	row.add_child(identity)

	var wallet := HBoxContainer.new()
	wallet.add_theme_constant_override("separation", 14)
	for key in EconData.RESOURCE_KEYS:
		var label := HudTheme.make_label()
		label.tooltip_text = String(key).capitalize()
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		_wallet_labels[key] = label
		wallet.add_child(label)
	row.add_child(wallet)

	_round_label = HudTheme.make_label()
	row.add_child(_round_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var phases := HBoxContainer.new()
	phases.add_theme_constant_override("separation", 4)
	for phase_name in TurnManager.get_phase_names():
		var chip := HudTheme.make_label(phase_name.capitalize(), HudTheme.SMALL_FONT_SIZE, HudTheme.MUTED)
		chip.add_theme_stylebox_override("normal", HudTheme.panel_style(Color(0, 0, 0, 0), 5, 5))
		_phase_labels.append(chip)
		phases.add_child(chip)
	row.add_child(phases)

	_turn_label = HudTheme.make_label()
	row.add_child(_turn_label)

	_next_button = HudTheme.make_button("", true)
	_next_button.custom_minimum_size.x = 190
	_next_button.pressed.connect(_on_next_button_pressed)
	row.add_child(_next_button)


#region Public API
func bind(player: Player, turn_manager: TurnManager, lander_manager: LanderManager,
		match_settings: MatchSettings, combat_manager: CombatManager) -> void:
	_player = player
	_turn_manager = turn_manager
	_lander_manager = lander_manager
	_match_settings = match_settings
	_combat_manager = combat_manager


func refresh() -> void:
	if _player == null or _turn_manager == null:
		return
	_identity_swatch.color = _player.get_color()
	_identity_label.text = "%s · %s" % [_player.get_display_name(), _player.get_species().get_display_name()]
	_identity_label.add_theme_color_override("font_color", _player.get_color().lightened(0.25))
	_refresh_wallet()
	_refresh_round()
	_refresh_phase_track()
	_refresh_turn()
#endregion


#region Private
func _refresh_wallet() -> void:
	var wallet := _player.get_wallet()
	var income := _expected_income()
	for key in EconData.RESOURCE_KEYS:
		var gain := income.get_amount(key)
		var label: Label = _wallet_labels[key]
		label.text = "%s %d%s" % [HudTheme.resource_icon(key), wallet.get_amount(key), "  +%d" % gain if gain > 0 else ""]
		label.tooltip_text = "%s: %d (+%d at your next upkeep)" % [String(key).capitalize(), wallet.get_amount(key), gain]


## What the player gains at their next upkeep: the flat gold plus each owned lander's upkeep.
func _expected_income() -> EconData:
	var income := EconData.new()
	income.set_amount(&"gold", _match_settings.get_upkeep_gold())
	for lander in _lander_manager.get_landers_owned_by(_player):
		income.add(lander.get_upkeep())
	return income


func _refresh_round() -> void:
	if _turn_manager.get_seasons().is_empty():
		_round_label.text = ""
		return
	var season := _turn_manager.get_current_season()
	_round_label.text = "Round %d · %s" % [_turn_manager.get_round_number(), TurnManager.Season.find_key(season).capitalize()]
	_round_label.add_theme_color_override("font_color", TurnManager.get_season_color(season).lightened(0.35))


func _refresh_phase_track() -> void:
	var is_main_loop := _turn_manager.get_game_state() == TurnManager.GameState.MAIN_LOOP
	for i in _phase_labels.size():
		var chip := _phase_labels[i]
		var is_current := is_main_loop and i == _turn_manager.get_game_phase()
		var is_admin := i in _turn_manager.get_admin_phases()
		chip.add_theme_color_override("font_color", HudTheme.TEXT if is_current else Color(HudTheme.MUTED, 0.55 if is_admin else 1.0))
		chip.add_theme_stylebox_override("normal",
			HudTheme.panel_style(HudTheme.ACCENT.darkened(0.45) if is_current else Color(0, 0, 0, 0), 5, 5))


func _refresh_turn() -> void:
	var state := _turn_manager.get_game_state()
	var active := _turn_manager.get_active_actor()
	if state == TurnManager.GameState.SETUP:
		_turn_label.text = "Setup"
		_turn_label.add_theme_color_override("font_color", HudTheme.MUTED)
		_set_next_button("Finish setup first", false)
		return

	var is_ours := active == _player
	_turn_label.text = "Your turn" if is_ours else "%s's turn" % HudTheme.actor_name(active)
	_turn_label.add_theme_color_override("font_color", HudTheme.actor_color(active).lightened(0.25))
	if not is_ours:
		_set_next_button("Waiting for %s…" % HudTheme.actor_name(active), false)
		return
	if _combat_manager.is_in_progress():
		_set_next_button("Finish the battle", false)
		return
	match _turn_manager.get_game_phase():
		TurnManager.Phase.DUSTCLOUD_COLLAPSE:
			_set_next_button("Place a lander first", false)
		TurnManager.Phase.BUYING:
			_set_next_button("End buying  ▸", true)
		TurnManager.Phase.COMBAT:
			_set_next_button("End turn  ▸", true)
		_:
			_set_next_button("…", false)


func _set_next_button(text: String, is_enabled: bool) -> void:
	_next_button.text = text
	_next_button.disabled = not is_enabled


func _on_next_button_pressed() -> void:
	action_requested.emit(Action.create(Action.Type.PROGRESS_TURN))
#endregion
