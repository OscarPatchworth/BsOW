# turn_manager.gd
class_name TurnManager
extends Node

## Owns the game flow: setup vs. main loop, the phase of the current turn,
## whose turn it is, and the season cycle.
##
## Signals are announced after a whole change is finished: start() and progress_phase()
## batch them, so a listener never sees e.g. the new active actor with the old phase.
## Within a batch they fire in the order the changes happened, once each.

signal game_state_changed(state: GameState)
signal game_phase_changed(phase: Phase)
signal turn_order_generated()
signal active_actor_changed(actor: Actor)
signal season_order_generated()
signal season_changed(season_index: int)
## `actor` lost their command tower and left the turn order.
signal actor_eliminated(actor: Actor)
## Only one actor is left (`winner`, or null if nobody is); the game state is now END.
signal game_over(winner: Actor)

enum GameState {
	SETUP,
	MAIN_LOOP,
	END,
}

enum Phase {
	UPKEEP,
	DUSTCLOUD_COLLAPSE,
	BUYING,
	COMBAT,
	CLEANUP,
}

enum Season {
	SUMMER,
	AUTUMN,
	WINTER,
	SPRING,
}

const SEASON_COLORS := {
	Season.SPRING: Color("#32a832"),
	Season.SUMMER: Color("#9e4266"),
	Season.AUTUMN: Color("#a16a33"),
	Season.WINTER: Color("#2a4d5e"),
}

## Phases that run automatically and can't be progressed by an actor.
const ADMIN_PHASES: Array[Phase] = [Phase.UPKEEP, Phase.CLEANUP]
## Phases an actor can't end with PROGRESS_TURN: they end when their action is done
## (DUSTCLOUD_COLLAPSE ends when the actor places a lander).
const NON_SKIPPABLE_PHASES: Array[Phase] = [Phase.DUSTCLOUD_COLLAPSE]

var _game_state: GameState = GameState.SETUP
var _game_phase: Phase = Phase.UPKEEP
var _turn_order: Array[Actor] = []
var _active_actor: Actor
var _round_number: int = 1
var _seasons: Array[Season] = []
var _season_index: int = 0

var _winner: Actor

var _batch_depth: int = 0
var _pending_notifications: Array[Callable] = []


#region Public API
func register_actor(actor: Actor) -> void:
	if actor not in _turn_order:
		_turn_order.append(actor)


## Called once everything is wired up (GameRoot.root_setup_finished).
func start() -> void:
	_begin_batch()
	_generate_turn_order()
	_generate_seasons()
	_notify(_emit_game_state_changed)
	_end_batch()


## Moves one phase forward; after CLEANUP, wraps to the next actor's UPKEEP.
## Doesn't skip admin phases by itself: the ActionManager queues that as a follow-up action.
func progress_phase() -> void:
	_begin_batch()
	var phase := get_game_phase()
	if phase == Phase.values()[-1]:
		_progress_turn_order()
		set_game_phase(Phase.values()[0])
	else:
		set_game_phase(Phase.values()[phase + 1])
	_end_batch()


## Takes `actor` out of the turn order. When only one actor is left, the game ends.
func eliminate_actor(actor: Actor) -> void:
	_begin_batch()
	var order := get_turn_order().duplicate()
	var index := order.find(actor)
	if index == -1:
		_end_batch()
		return
	order.erase(actor)
	set_turn_order(order)
	_notify(func() -> void: actor_eliminated.emit(actor))
	if order.size() <= 1:
		_winner = order[0] if not order.is_empty() else null
		set_game_state(GameState.END)
		_notify(func() -> void: game_over.emit(_winner))
	elif actor == get_active_actor():
		set_active_actor(order[index % order.size()])
	_end_batch()


func get_winner() -> Actor:
	return _winner


## Ends setup: the main loop starts with the active actor's UPKEEP.
func begin_main_loop() -> void:
	_begin_batch()
	set_game_state(GameState.MAIN_LOOP)
	set_game_phase(Phase.UPKEEP)
	_end_batch()


func get_turn_order_names() -> Array[String]:
	var names: Array[String] = []
	for actor in get_turn_order():
		names.append(actor.name)
	return names


func get_season_names() -> Array[String]:
	var names: Array[String] = []
	for season in get_seasons():
		names.append(Season.keys()[season])
	return names


func get_current_season() -> Season:
	return get_seasons()[get_season_index()]


static func get_season_color(season: Season) -> Color:
	return SEASON_COLORS[season]


## "WINTER" -> Season.WINTER, or -1 if there's no such season.
static func season_from_name(season_name: String) -> int:
	return Season.get(season_name, -1)


static func get_phase_name(phase: Phase) -> String:
	return Phase.find_key(phase) if Phase.find_key(phase) != null else "UNKNOWN"


static func get_phase_names() -> Array[String]:
	var names: Array[String] = []
	names.assign(Phase.keys())
	return names


func to_debug_dictionary() -> Dictionary:
	return {
		"game_state": GameState.find_key(get_game_state()),
		"game_phase": get_phase_name(get_game_phase()),
		"turn_order": get_turn_order_names(),
		"active_actor": get_active_actor(),
		"round_number": get_round_number(),
	}
#endregion


#region Accessors
func get_game_state() -> GameState:
	return AbilitySystem.resolve_get(self, &"game_state", _game_state)


## Also announces game_state_changed.
func set_game_state(value: GameState) -> void:
	_game_state = AbilitySystem.resolve_set(self, &"game_state", _game_state, value)
	_notify(_emit_game_state_changed)


func get_game_phase() -> Phase:
	return AbilitySystem.resolve_get(self, &"game_phase", _game_phase)


## Also announces game_phase_changed.
func set_game_phase(value: Phase) -> void:
	_game_phase = AbilitySystem.resolve_set(self, &"game_phase", _game_phase, value)
	_notify(_emit_game_phase_changed)


func get_turn_order() -> Array[Actor]:
	return AbilitySystem.resolve_get(self, &"turn_order", _turn_order)


func set_turn_order(value: Array[Actor]) -> void:
	_turn_order = AbilitySystem.resolve_set(self, &"turn_order", _turn_order, value)


func get_active_actor() -> Actor:
	return AbilitySystem.resolve_get(self, &"active_actor", _active_actor)


## Also announces active_actor_changed.
func set_active_actor(value: Actor) -> void:
	_active_actor = AbilitySystem.resolve_set(self, &"active_actor", _active_actor, value)
	_notify(_emit_active_actor_changed)


func get_round_number() -> int:
	return AbilitySystem.resolve_get(self, &"round_number", _round_number)


func set_round_number(value: int) -> void:
	_round_number = AbilitySystem.resolve_set(self, &"round_number", _round_number, value)


func get_seasons() -> Array[Season]:
	return AbilitySystem.resolve_get(self, &"seasons", _seasons)


func get_season_index() -> int:
	return AbilitySystem.resolve_get(self, &"season_index", _season_index)


## Also announces season_changed.
func set_season_index(value: int) -> void:
	_season_index = AbilitySystem.resolve_set(self, &"season_index", _season_index, value)
	_notify(_emit_season_changed)


func get_admin_phases() -> Array[Phase]:
	return AbilitySystem.resolve_get(self, &"admin_phases", ADMIN_PHASES)


func get_non_skippable_phases() -> Array[Phase]:
	return AbilitySystem.resolve_get(self, &"non_skippable_phases", NON_SKIPPABLE_PHASES)
#endregion


#region Private
func _generate_turn_order() -> void:
	var order := get_turn_order().duplicate()
	order.shuffle()
	set_turn_order(order)
	print("TurnManager | Turn order: " + str(get_turn_order_names()))
	# Announce the order before the active actor: the turn order UI must exist to highlight it.
	_notify(turn_order_generated.emit)
	set_active_actor(get_turn_order()[0])


func _generate_seasons() -> void:
	_seasons.assign(Season.values())
	_season_index = 0
	print("TurnManager | Starting season: " + Season.keys()[get_current_season()])
	print("TurnManager | Season order: " + str(get_season_names()))
	_notify(season_order_generated.emit)


func _progress_turn_order() -> void:
	var order := get_turn_order()
	var next_index := order.find(get_active_actor()) + 1
	if next_index >= order.size():
		# Wrapped back to the first actor: a new round begins.
		next_index = 0
		set_round_number(get_round_number() + 1)
		_progress_season()
	set_active_actor(order[next_index])


func _progress_season() -> void:
	var next_index := (get_season_index() + 1) % get_seasons().size()
	set_season_index(next_index)
	print("TurnManager | New round, season: " + Season.keys()[get_current_season()])
#endregion


#region Notification batching
func _begin_batch() -> void:
	_batch_depth += 1


func _end_batch() -> void:
	_batch_depth -= 1
	if _batch_depth > 0:
		return
	var notifications := _pending_notifications
	_pending_notifications = []
	for notification in notifications:
		notification.call()


## Runs `notification` now, or at the end of the current batch (once, however often it's queued).
func _notify(notification: Callable) -> void:
	if _batch_depth == 0:
		notification.call()
	elif notification not in _pending_notifications:
		_pending_notifications.append(notification)


# Emitters read the value when they fire, so a batched signal carries the final value.
func _emit_game_state_changed() -> void:
	game_state_changed.emit(get_game_state())


func _emit_game_phase_changed() -> void:
	game_phase_changed.emit(get_game_phase())


func _emit_active_actor_changed() -> void:
	active_actor_changed.emit(get_active_actor())


func _emit_season_changed() -> void:
	season_changed.emit(get_season_index())
#endregion
