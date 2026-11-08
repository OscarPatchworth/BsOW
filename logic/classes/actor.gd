# actor.gd
class_name Actor
extends Node

## Base class for anything that takes turns: the local Player and AI opponents.
## Every actor is wired the same way (GameRoot._add_actor) and plays by the same rules:
##   * it changes the game only by requesting Actions (request_action),
##   * _take_phase() is called when one of its phases starts and it should act,
##   * _enter_combat() is called when a contest it is part of starts,
##   * _action_resolved() is called after any action resolves.
## A human Player acts through its UI instead of in _take_phase; an AI acts in code.

## An Action this actor wants to take, with `actor` already set. GameRoot connects this
## to ActionManager.request_action.
signal action_requested(action: Action)

var _species: SpeciesData
var _wallet: EconData

var _action_manager: ActionManager
var _turn_manager: TurnManager
var _lander_manager: LanderManager
var _combat_manager: CombatManager

## Which side of the current contest this actor is on, or -1 when not in combat.
var _combat_side: int = -1


#region Public API
func bind_action_manager(action_manager: ActionManager) -> void:
	_action_manager = action_manager
	action_manager.action_resolved.connect(_on_action_manager_action_resolved)


## Stamps this actor on `action` and sends it to the ActionManager.
func request_action(action: Action) -> void:
	action.set_actor(self)
	action_requested.emit(action)


func bind_turn_manager(turn_manager: TurnManager) -> void:
	_turn_manager = turn_manager
	turn_manager.game_phase_changed.connect(_on_turn_manager_game_phase_changed)


func bind_lander_manager(lander_manager: LanderManager) -> void:
	_lander_manager = lander_manager


func bind_combat_manager(combat_manager: CombatManager) -> void:
	_combat_manager = combat_manager
	combat_manager.combat_started.connect(_on_combat_manager_combat_started)


func is_active_actor() -> bool:
	return _turn_manager.get_active_actor() == self
#endregion


#region Accessors
func get_species() -> SpeciesData:
	return AbilitySystem.resolve_get(self, &"species", _species)


func set_species(value: SpeciesData) -> void:
	_species = AbilitySystem.resolve_set(self, &"species", _species, value)


func get_wallet() -> EconData:
	return AbilitySystem.resolve_get(self, &"wallet", _wallet)


func set_wallet(value: EconData) -> void:
	_wallet = AbilitySystem.resolve_set(self, &"wallet", _wallet, value)


func get_combat_side() -> int:
	return AbilitySystem.resolve_get(self, &"combat_side", _combat_side)


func set_combat_side(value: int) -> void:
	_combat_side = AbilitySystem.resolve_set(self, &"combat_side", _combat_side, value)
#endregion


#region Signal handlers
func _on_action_manager_action_resolved(action: Action) -> void:
	_action_resolved(action)


func _on_turn_manager_game_phase_changed(phase: TurnManager.Phase) -> void:
	_game_phase_changed(phase)
	var is_playable_phase := (_turn_manager.get_game_state() == TurnManager.GameState.MAIN_LOOP
		and phase not in _turn_manager.get_admin_phases())
	if is_playable_phase and is_active_actor():
		_take_phase(phase)


func _on_combat_manager_combat_started(contest: Contest) -> void:
	if not contest.is_involved(self):
		return  # Not our fight. (Spectating could hook in here later.)
	set_combat_side(contest.get_side_of(self))
	_enter_combat(contest)
#endregion


#region Virtual
## Override in subclasses: called whenever the game phase changes, whoever's turn it is.
func _game_phase_changed(_phase: TurnManager.Phase) -> void:
	pass


## Override in subclasses: it's this actor's turn and `phase` has started.
## Request actions here, ending with PROGRESS_TURN (PLACE_LANDER progresses by itself).
func _take_phase(_phase: TurnManager.Phase) -> void:
	pass


## Override in subclasses: called when a contest this actor is part of starts.
func _enter_combat(_contest: Contest) -> void:
	pass


## Override in subclasses: called after any action (by anyone) has resolved.
func _action_resolved(_action: Action) -> void:
	pass
#endregion
