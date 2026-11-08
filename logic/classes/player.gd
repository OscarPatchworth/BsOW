# player.gd
class_name Player
extends Actor

## The local human player. Owns a PlayerController (world input), a UiManager (HUD)
## and a SelectorManager (what is currently selected), and connects them to the game.
## Everything the children request is sent on as an Action through request_action().

var _draw_3d: Draw3D
var _match_settings: MatchSettings

@onready var _controller: PlayerController = find_child("PlayerController")
@onready var _ui: UiManager = find_child("UiManager")
@onready var _selector_manager: SelectorManager = find_child("SelectorManager")


func _ready() -> void:
	_bind_children()
	_connect_children()
	_connect_managers()


#region Public API
func bind_draw_3d(draw_3d: Draw3D) -> void:
	_draw_3d = draw_3d


func bind_match_settings(match_settings: MatchSettings) -> void:
	_match_settings = match_settings


func get_display_name() -> String:
	return "You"


func get_selector_manager() -> SelectorManager:
	return _selector_manager
#endregion


#region Signal handlers (managers; HUD updates only)
func _on_combat_manager_combat_updated(contest: Contest) -> void:
	if contest.is_involved(self):
		_ui.update_combat(contest)


func _on_combat_manager_combat_resolved(outcomes: Array[CombatOutcome]) -> void:
	_ui.show_combat_outcome(outcomes)
	_controller.exit_combat()


func _on_turn_manager_game_state_changed(state: TurnManager.GameState) -> void:
	_controller.apply_game_state(state)
	_ui.apply_game_state(state)


func _on_turn_manager_turn_order_generated() -> void:
	_ui.show_turn_order()
	if _turn_manager.get_active_actor() == self:
		_controller.set_is_active_player(true)


func _on_turn_manager_active_actor_changed(active_actor: Actor) -> void:
	_ui.apply_active_actor(active_actor)
	_controller.apply_active_actor(active_actor)


func _on_turn_manager_season_order_generated() -> void:
	_ui.show_seasons()


func _on_turn_manager_season_changed(season_index: int) -> void:
	_ui.apply_season(season_index)


#endregion


#region Signal handlers (children)
func _on_child_action_requested(action: Action) -> void:
	request_action(action)


func _on_ui_combat_unit_selected(unit: UnitInstance) -> void:
	_request_combat_unit(Action.Type.SELECT_COMBAT_UNIT, unit)


func _on_ui_combat_unit_deselected(unit: UnitInstance) -> void:
	_request_combat_unit(Action.Type.DESELECT_COMBAT_UNIT, unit)


func _on_ui_combat_ready() -> void:
	request_action(Action.create(Action.Type.DECLARE_COMBAT_READY))


func _on_ui_combat_not_ready() -> void:
	request_action(Action.create(Action.Type.WITHDRAW_COMBAT_READY))
#endregion


#region Virtual overrides
func _game_phase_changed(phase: TurnManager.Phase) -> void:
	_controller.apply_game_phase(phase)
	_ui.apply_game_phase(phase)


func _action_resolved(action: Action) -> void:
	match action.get_type():
		Action.Type.PLACE_BIOME:
			if action.get_actor() == self:
				_controller.on_setup_biome_placed()
				_ui.on_setup_biome_placed(action)
		Action.Type.PLACE_BUILDING:
			if action.get_actor() == self:
				_controller.on_command_tower_placed()
		Action.Type.PURCHASE:
			if action.get_actor() == self:
				_ui.refresh_lander_panel()
		Action.Type.MOVE_UNITS:
			if (action.get_actor() == self
					or action.get_source_lander() == _selector_manager.get_selected_lander()
					or action.get_target_lander() == _selector_manager.get_target_lander()):
				_ui.on_units_moved()


func _enter_combat(contest: Contest) -> void:
	_ui.show_combat(contest)
	_controller.enter_combat()
#endregion


#region Private
func _request_combat_unit(type: Action.Type, unit: UnitInstance) -> void:
	var action := Action.create(type)
	action.set_units([unit] as Array[UnitInstance])
	request_action(action)


func _bind_children() -> void:
	_selector_manager.bind_player(self)

	_controller.bind_player(self)
	_controller.bind_selector_manager(_selector_manager)
	_controller.bind_turn_manager(_turn_manager)
	_controller.bind_lander_manager(_lander_manager)
	_controller.bind_draw_3d(_draw_3d)

	_ui.bind_player(self)
	_ui.bind_selector_manager(_selector_manager)
	_ui.bind_turn_manager(_turn_manager)
	_ui.bind_lander_manager(_lander_manager)
	_ui.bind_combat_manager(_combat_manager)
	_ui.bind_match_settings(_match_settings)
	_ui.bind_wallet(get_wallet())


func _connect_children() -> void:
	_controller.action_requested.connect(_on_child_action_requested)
	_controller.lander_selected.connect(_selector_manager.select_lander)
	_controller.lander_view_requested.connect(_ui.show_lander_panel)
	_controller.movement_ui_requested.connect(_ui.show_movement_panel)

	_ui.action_requested.connect(_on_child_action_requested)
	_ui.combat_unit_selected.connect(_on_ui_combat_unit_selected)
	_ui.combat_unit_deselected.connect(_on_ui_combat_unit_deselected)
	_ui.combat_ready.connect(_on_ui_combat_ready)
	_ui.combat_not_ready.connect(_on_ui_combat_not_ready)
	_ui.setup_biome_selected.connect(_controller.on_setup_biome_selected)
	_ui.all_setup_biomes_placed.connect(_controller.on_all_setup_biomes_placed)

	get_wallet().amounts_changed.connect(_ui.on_wallet_changed)


## Signals only the HUD needs. Turn phases, combat start and resolved actions are
## connected by Actor like for every other actor.
func _connect_managers() -> void:
	_combat_manager.combat_updated.connect(_on_combat_manager_combat_updated)
	_combat_manager.combat_resolved.connect(_on_combat_manager_combat_resolved)
	_turn_manager.game_state_changed.connect(_on_turn_manager_game_state_changed)
	_turn_manager.turn_order_generated.connect(_on_turn_manager_turn_order_generated)
	_turn_manager.active_actor_changed.connect(_on_turn_manager_active_actor_changed)
	_turn_manager.season_order_generated.connect(_on_turn_manager_season_order_generated)
	_turn_manager.season_changed.connect(_on_turn_manager_season_changed)
#endregion
