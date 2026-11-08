# turn_manager.gd
class_name TurnManager
extends Node

## Owns the game flow: setup vs. main loop, the phase of the current turn,
## whose turn it is, and the season cycle.

signal game_state_changed(state: GameState)
signal game_phase_changed(phase: Phase)
signal turn_order_generated()
signal active_actor_changed(actor: Actor)
signal season_order_generated()
signal season_changed(season_index: int)

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
## Phases an actor must act in before moving on.
const NON_SKIPPABLE_PHASES: Array[Phase] = [Phase.DUSTCLOUD_COLLAPSE]

var _game_state: GameState = GameState.SETUP
var _game_phase: Phase = Phase.UPKEEP
var _turn_order: Array[Actor] = []
var _active_actor: Actor
var _round_number: int = 1
var _seasons: Array[Season] = []
var _season_index: int = 0


#region Public API
func register_actor(actor: Actor) -> void:
	if actor not in _turn_order:
		_turn_order.append(actor)


## Called once everything is wired up (GameRoot.root_setup_finished).
func start() -> void:
	_generate_turn_order()
	_generate_seasons()
	game_state_changed.emit(get_game_state())


## Moves to the next phase; wraps to the next actor after CLEANUP.
## Admin phases are announced and then skipped automatically.
func progress_phase() -> void:
	var phase := get_game_phase()
	if phase == Phase.values()[-1]:
		set_game_phase(Phase.values()[0])
		_progress_turn_order()
	else:
		set_game_phase(Phase.values()[phase + 1])
	game_phase_changed.emit(get_game_phase())

	if get_game_phase() in get_admin_phases():
		progress_phase()


## Ends the setup stage and starts the main loop.
func finish_setup() -> void:
	if get_game_state() != GameState.SETUP:
		return
	await get_tree().process_frame
	set_game_state(GameState.MAIN_LOOP)
	progress_phase()


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


## Also emits game_state_changed.
func set_game_state(value: GameState) -> void:
	_game_state = AbilitySystem.resolve_set(self, &"game_state", _game_state, value)
	game_state_changed.emit(get_game_state())


func get_game_phase() -> Phase:
	return AbilitySystem.resolve_get(self, &"game_phase", _game_phase)


## Does NOT emit game_phase_changed; progress_phase() does that.
func set_game_phase(value: Phase) -> void:
	_game_phase = AbilitySystem.resolve_set(self, &"game_phase", _game_phase, value)


func get_turn_order() -> Array[Actor]:
	return AbilitySystem.resolve_get(self, &"turn_order", _turn_order)


func set_turn_order(value: Array[Actor]) -> void:
	_turn_order = AbilitySystem.resolve_set(self, &"turn_order", _turn_order, value)


func get_active_actor() -> Actor:
	return AbilitySystem.resolve_get(self, &"active_actor", _active_actor)


## Also emits active_actor_changed.
func set_active_actor(value: Actor) -> void:
	_active_actor = AbilitySystem.resolve_set(self, &"active_actor", _active_actor, value)
	active_actor_changed.emit(get_active_actor())


func get_round_number() -> int:
	return AbilitySystem.resolve_get(self, &"round_number", _round_number)


func set_round_number(value: int) -> void:
	_round_number = AbilitySystem.resolve_set(self, &"round_number", _round_number, value)


func get_seasons() -> Array[Season]:
	return AbilitySystem.resolve_get(self, &"seasons", _seasons)


func get_season_index() -> int:
	return AbilitySystem.resolve_get(self, &"season_index", _season_index)


## Also emits season_changed.
func set_season_index(value: int) -> void:
	_season_index = AbilitySystem.resolve_set(self, &"season_index", _season_index, value)
	season_changed.emit(get_season_index())


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
	# Store the first actor before announcing the order (listeners read get_active_actor()),
	# then announce the active actor once the order exists.
	_active_actor = AbilitySystem.resolve_set(self, &"active_actor", _active_actor, get_turn_order()[0])
	turn_order_generated.emit()
	active_actor_changed.emit(get_active_actor())


func _generate_seasons() -> void:
	_seasons.assign(Season.values())
	_season_index = 0
	print("TurnManager | Starting season: " + Season.keys()[get_current_season()])
	print("TurnManager | Season order: " + str(get_season_names()))
	season_order_generated.emit()


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
