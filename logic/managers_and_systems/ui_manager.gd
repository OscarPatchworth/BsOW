# ui_manager.gd
class_name UiManager
extends Control

## Root of the player's HUD. Hands dependencies down to the panels and funnels
## their requests up to the Player.

signal action_requested(action: Action)
signal combat_unit_selected(unit: UnitInstance)
signal combat_unit_deselected(unit: UnitInstance)
signal combat_ready()
signal combat_not_ready()
signal setup_biome_selected(biome_data: BiomeData)
signal all_setup_biomes_placed()

var _player: Player
var _turn_manager: TurnManager
var _selector_manager: SelectorManager

@onready var _lander_panel: LanderPanel = find_child("LanderPanel")
@onready var _turn_panel: TurnPanel = find_child("TurnPanel")
@onready var _combat_panel: CombatPanel = find_child("CombatPanel")
@onready var _players_panel: PlayersPanel = find_child("PlayersPanel")
@onready var _seasons_panel: SeasonsPanel = find_child("SeasonsPanel")
@onready var _movement_panel: MovementPanel = find_child("MovementPanel")
@onready var _purchase_panel: PurchasePanel = find_child("PurchasePanel")
@onready var _wallet_panel: WalletPanel = find_child("WalletPanel")
@onready var _setup_panel: SetupPanel = find_child("SetupPanel")


func _ready() -> void:
	_connect_panels()
	_lander_panel.hide()
	_combat_panel.hide()
	_movement_panel.hide()


#region Binding
func bind_player(player: Player) -> void:
	_player = player
	_combat_panel.bind_player(player)
	_purchase_panel.bind_player(player)
	_setup_panel.bind_player(player)


func bind_selector_manager(selector_manager: SelectorManager) -> void:
	_selector_manager = selector_manager
	_lander_panel.bind_selector_manager(selector_manager)


func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager
	_players_panel.bind_turn_manager(turn_manager)
	_seasons_panel.bind_turn_manager(turn_manager)
	_turn_panel.bind_turn_manager(turn_manager)
	_setup_panel.bind_turn_manager(turn_manager)


func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_panel.bind_lander_manager(lander_manager)
	_movement_panel.bind_lander_manager(lander_manager)
	_purchase_panel.bind_lander_manager(lander_manager)


func bind_combat_manager(combat_manager: CombatManager) -> void:
	_combat_panel.bind_combat_manager(combat_manager)


func bind_match_settings(match_settings: MatchSettings) -> void:
	_setup_panel.bind_match_settings(match_settings)


func bind_wallet(wallet: EconData) -> void:
	_wallet_panel.bind_wallet(wallet)
#endregion


#region Public API (called by Player)
func show_lander_panel(_lander: Lander) -> void:
	_lander_panel.show()
	_lander_panel.refresh()


func refresh_lander_panel() -> void:
	_lander_panel.refresh()


func on_units_moved() -> void:
	_selector_manager.clear_selected_units()
	_selector_manager.set_target_lander(null)
	_lander_panel.refresh()


func show_movement_panel(from_lander: Lander, to_lander: Lander) -> void:
	_movement_panel.open(from_lander, to_lander)


func show_combat(contest: Contest) -> void:
	_lander_panel.hide()
	_turn_panel.hide()
	_combat_panel.show()
	_combat_panel.open(contest)


func update_combat(contest: Contest) -> void:
	_combat_panel.refresh(contest)


func show_combat_ended(_contest: Contest) -> void:
	pass  # The combat panel already shows the last round; the HUD rebuild adds a summary.


func show_combat_outcome(outcomes: Array[CombatOutcome]) -> void:
	_combat_panel.show_outcome(outcomes)


func apply_game_state(state: TurnManager.GameState) -> void:
	_players_panel.apply_game_state(state)
	_seasons_panel.apply_game_state(state)
	_setup_panel.apply_game_state(state)
	_turn_panel.apply_game_state(state)
	_wallet_panel.apply_game_state(state)


func apply_game_phase(phase: TurnManager.Phase) -> void:
	_turn_panel.refresh()
	var is_our_turn := _turn_manager.get_active_actor() == _player
	match phase:
		TurnManager.Phase.BUYING:
			if is_our_turn:
				_purchase_panel.open_market()
		TurnManager.Phase.COMBAT:
			if is_our_turn:
				_purchase_panel.hide()


func show_turn_order() -> void:
	_players_panel.show_turn_order()


func apply_active_actor(active_actor: Actor) -> void:
	_players_panel.highlight_active_actor(active_actor)


func show_seasons() -> void:
	_seasons_panel.show_seasons()


func apply_season(season_index: int) -> void:
	_seasons_panel.highlight_season(season_index)


func on_setup_biome_placed(action: Action) -> void:
	_setup_panel.on_biome_placed(action)


func on_wallet_changed() -> void:
	_wallet_panel.refresh()
#endregion


#region Signal handlers
func _on_purchase_panel_market_closed() -> void:
	if _turn_manager.get_game_phase() == TurnManager.Phase.BUYING:
		action_requested.emit(Action.create(Action.Type.PROGRESS_TURN))


func _on_combat_panel_display_toggled(is_hidden: bool) -> void:
	if is_hidden:
		_turn_panel.hide()
		_lander_panel.hide()
		_players_panel.hide()
	else:
		_players_panel.show()
		_turn_panel.show()


func _on_combat_panel_closed() -> void:
	_turn_panel.show()
#endregion


#region Private
func _connect_panels() -> void:
	_lander_panel.action_requested.connect(action_requested.emit)
	_turn_panel.action_requested.connect(action_requested.emit)
	_movement_panel.action_requested.connect(action_requested.emit)
	_purchase_panel.action_requested.connect(action_requested.emit)
	_combat_panel.action_requested.connect(action_requested.emit)

	_combat_panel.unit_selected.connect(combat_unit_selected.emit)
	_combat_panel.unit_deselected.connect(combat_unit_deselected.emit)
	_combat_panel.ready_pressed.connect(combat_ready.emit)
	_combat_panel.not_ready_pressed.connect(combat_not_ready.emit)
	_combat_panel.display_toggled.connect(_on_combat_panel_display_toggled)
	_combat_panel.closed.connect(_on_combat_panel_closed)

	_purchase_panel.market_closed.connect(_on_purchase_panel_market_closed)

	_setup_panel.biome_selected.connect(setup_biome_selected.emit)
	_setup_panel.all_biomes_placed.connect(all_setup_biomes_placed.emit)
#endregion
