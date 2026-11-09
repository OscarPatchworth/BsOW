# player.gd
class_name Player
extends Actor

## The local human player. Owns a PlayerController (world input and previews), a UiManager (HUD)
## and a SelectorManager (what is currently selected), and connects them to the game.
## Everything the children request is sent on as an Action through request_action().

var _draw_3d: Draw3D
var _match_settings: MatchSettings
var _gravity_system: GravitySystem

@onready var _controller: PlayerController = find_child("PlayerController")
@onready var _ui: UiManager = find_child("UiManager")
@onready var _selector_manager: SelectorManager = find_child("SelectorManager")


## MOVE_UNITS -> who owned the target before it resolved (to tell "they took your lander").
var _owner_before_move := {}


func _ready() -> void:
	_bind_children()
	_connect_children()
	_connect_managers()


## The selection ring follows whatever the lander panel is showing.
func _process(_delta: float) -> void:
	var inspector := _ui.get_inspector()
	_controller.get_markers().show_selection(inspector.get_lander() if inspector.visible else null)


#region Public API
func bind_draw_3d(draw_3d: Draw3D) -> void:
	_draw_3d = draw_3d


func bind_match_settings(match_settings: MatchSettings) -> void:
	_match_settings = match_settings


func bind_gravity_system(gravity_system: GravitySystem) -> void:
	_gravity_system = gravity_system


func get_display_name() -> String:
	return "You"


func get_selector_manager() -> SelectorManager:
	return _selector_manager


func get_ui() -> UiManager:
	return _ui


func get_controller() -> PlayerController:
	return _controller
#endregion


#region Signal handlers (managers; HUD updates only)
func _on_combat_manager_combat_updated(contest: Contest) -> void:
	if contest.is_involved(self):
		_ui.update_combat(contest)


## One round's dice. The battle may go on to another round.
func _on_combat_manager_combat_resolved(outcomes: Array[CombatOutcome]) -> void:
	if _combat_manager.get_contest().is_involved(self):
		_ui.show_combat_outcome(outcomes)


func _on_combat_manager_combat_ended(contest: Contest) -> void:
	if contest.is_involved(self):
		_ui.show_combat_ended(contest)
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


func _on_turn_manager_actor_eliminated(actor: Actor) -> void:
	_ui.on_actor_eliminated(actor)


func _on_turn_manager_game_over(winner: Actor) -> void:
	_ui.show_game_over(winner)
#endregion


#region Signal handlers (children)
func _on_child_action_requested(action: Action) -> void:
	request_action(action)
#endregion


#region Virtual overrides
func _game_phase_changed(phase: TurnManager.Phase) -> void:
	_controller.apply_game_phase(phase)
	_ui.apply_game_phase(phase)


func _action_resolved(action: Action) -> void:
	if action.get_actor() == self:
		match action.get_type():
			Action.Type.PLACE_BIOME:
				_controller.on_setup_biome_placed()
				_ui.on_setup_biome_placed(action)
			Action.Type.PLACE_BUILDING:
				_controller.on_command_tower_placed()
	elif action.get_actor() != null and not action.is_system():
		_flash_affected_landers(action)
		_mark_others_move(action)
	_ui.on_action_resolved(action)


func _action_rejected(action: Action, reason: String) -> void:
	_ui.on_action_rejected(action, reason)


func _enter_combat(contest: Contest) -> void:
	_ui.show_combat(contest)
	_controller.enter_combat()
#endregion


#region Private
## Shows where another actor just acted, in their colour.
func _flash_affected_landers(action: Action) -> void:
	var color := action.get_actor().get_color()
	match action.get_type():
		Action.Type.PLACE_LANDER:
			_lander_manager.get_landers()[-1].flash(color)
		Action.Type.PURCHASE:
			action.get_target_lander().flash(color)
		Action.Type.MOVE_UNITS, Action.Type.ATTACK:
			action.get_source_lander().flash(color)
			action.get_target_lander().flash(color)


## Another player's move: a short arrow, and an alert when it takes something of ours.
func _mark_others_move(action: Action) -> void:
	if action.get_type() != Action.Type.MOVE_UNITS:
		return
	var target := action.get_target_lander()
	var label := ""
	match action.get_building_fate():
		Action.BuildingFate.CAPTURE:
			label = "Captured!"
		Action.BuildingFate.RAZE:
			label = "Razed!"
	_controller.get_markers().add_arrow(action, action.get_source_lander(), target, action.get_actor().get_color(), label, 3.0)
	if _owner_before_move.get(action) == self:
		_ui.alert("%s %s your %s lander!" % [action.get_actor().get_display_name(),
			"razed the building on" if action.get_building_fate() == Action.BuildingFate.RAZE else "took", EventLog.lander_name(target)])
	_owner_before_move.erase(action)


## Every battle gets an arrow from attacker to defender until it ends, ours or not.
func _on_any_combat_started(contest: Contest) -> void:
	var attacker := contest.get_actor(Contest.Side.ATTACKER)
	var defender := contest.get_actor(Contest.Side.DEFENDER)
	var defender_lander := contest.get_lander(Contest.Side.DEFENDER)
	var label := "UNDER ATTACK!" if defender == self else ("ATTACKING" if attacker == self
		else "%s attacks %s" % [attacker.get_display_name(), defender.get_display_name() if defender != null else "?"])
	_controller.get_markers().add_arrow(contest, contest.get_lander(Contest.Side.ATTACKER), defender_lander,
		attacker.get_color(), label)
	if defender == self:
		_ui.alert("⚔ %s is attacking your %s lander!" % [attacker.get_display_name(), EventLog.lander_name(defender_lander)])


func _on_any_combat_ended(contest: Contest) -> void:
	_controller.get_markers().remove_arrow(contest)


func _on_action_manager_action_resolving(action: Action) -> void:
	if action.get_type() == Action.Type.MOVE_UNITS and action.get_actor() != self:
		_owner_before_move[action] = action.get_target_lander().get_owner_actor()


func _bind_children() -> void:
	_selector_manager.bind_player(self)

	_controller.bind_player(self)
	_controller.bind_selector_manager(_selector_manager)
	_controller.bind_turn_manager(_turn_manager)
	_controller.bind_lander_manager(_lander_manager)
	_controller.bind_gravity_system(_gravity_system)

	_ui.bind_player(self)
	_ui.bind_selector_manager(_selector_manager)
	_ui.bind_turn_manager(_turn_manager)
	_ui.bind_lander_manager(_lander_manager)
	_ui.bind_combat_manager(_combat_manager)
	_ui.bind_match_settings(_match_settings)
	_ui.finish_binding()


func _connect_children() -> void:
	_controller.action_requested.connect(_on_child_action_requested)
	_controller.lander_selected.connect(_selector_manager.select_lander)
	_controller.lander_view_requested.connect(_ui.show_lander_panel)
	_controller.movement_ui_requested.connect(_ui.show_movement_panel)

	_ui.action_requested.connect(_on_child_action_requested)
	_ui.setup_biome_selected.connect(_controller.on_setup_biome_selected)
	_ui.all_setup_biomes_placed.connect(_controller.on_all_setup_biomes_placed)
	_ui.camera_focus_requested.connect(_controller.focus_camera_on)

	get_wallet().amounts_changed.connect(_ui.on_wallet_changed)


## Signals only the HUD needs. Turn phases, combat start and resolved actions are
## connected by Actor like for every other actor.
func _connect_managers() -> void:
	_combat_manager.combat_updated.connect(_on_combat_manager_combat_updated)
	_combat_manager.combat_resolved.connect(_on_combat_manager_combat_resolved)
	_combat_manager.combat_ended.connect(_on_combat_manager_combat_ended)
	_combat_manager.combat_started.connect(_on_any_combat_started)
	_combat_manager.combat_ended.connect(_on_any_combat_ended)
	_action_manager.action_resolving.connect(_on_action_manager_action_resolving)
	_turn_manager.game_state_changed.connect(_on_turn_manager_game_state_changed)
	_turn_manager.turn_order_generated.connect(_on_turn_manager_turn_order_generated)
	_turn_manager.active_actor_changed.connect(_on_turn_manager_active_actor_changed)
	_turn_manager.season_order_generated.connect(_on_turn_manager_season_order_generated)
	_turn_manager.season_changed.connect(_on_turn_manager_season_changed)
	_turn_manager.actor_eliminated.connect(_on_turn_manager_actor_eliminated)
	_turn_manager.game_over.connect(_on_turn_manager_game_over)
#endregion
