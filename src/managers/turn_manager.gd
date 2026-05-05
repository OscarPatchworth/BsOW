# turn_manager.gd
# Managers the game flow between Setup-GameLoop-End, players and phases

class_name TurnManager
extends Node

#region Declarations
# Signals
signal game_phased_changed(game_phase: GameLoop)
signal combat_assign(contest: Contest)
signal turn_phase_updated(phase: GameLoop)
signal turn_order_generated
signal actor_turn_changed(active: Actor)
signal season_order_generated
signal season_changed(sea_indx: int)
signal current_game_state(state: GameSequence)

# Enums
enum GameSequence {
	SETUP,
	GAME_LOOP,
	END
}

enum GameLoop {
	UPKEEP,
	DUSTCLOUD_COLLASPE_PHASE,
	BUYING_PHASE,
	COMBAT_PHASE,
	CLEANUP
}

enum CombatLoop {
	MOVE_UNITS,
	ASSIGN_COMBATANTS,
	DAMAGE
}

enum Season {
	SUMMER,
	AUTUMN,
	WINTER,
	SPRING
}

# Constants
const SEASON_COLORS := {
	Season.SPRING: Color("#32a832"),
	Season.SUMMER: Color("#9e4266"),
	Season.AUTUMN: Color("#a16a33"),
	Season.WINTER: Color("#2a4d5e"),
}

# Static Variables
# Exported Data
# Scene Refs
# Runtime Refs
var game_state: GameSequence = GameSequence.SETUP
var game_phase: GameLoop = GameLoop.UPKEEP
var combat_phase: CombatLoop = CombatLoop.MOVE_UNITS 
var turn_order: Array[Actor]
var active_actor: Actor
var turn_number: int = 1
var game_seasons: Array[Season]
var cur_season: Season
var cur_season_ind: int

var admin_game_phases := [GameLoop.UPKEEP, GameLoop.CLEANUP]
var non_skipable_phases := [GameLoop.DUSTCLOUD_COLLASPE_PHASE]

var actors: Array

#endregion

#region Internal Types
#endregion


###################################################################################################
#region Lifecycle
#endregion

#region Setup Flow
func bind_actor_to_actor_group(a: Actor):
	if not a in turn_order:
		turn_order.append(a)


func self_init():
	init_turn_order()
	init_season()
	current_game_state.emit(game_state)


func init_turn_order():
	turn_order.shuffle()
	print(turn_order)
	active_actor = turn_order[0]
	turn_order_generated.emit()
	actor_turn_changed.emit(turn_order[0])


func init_season():
	# Generate game Seasons from Seasons enum
	for sea in Season.values():
		game_seasons.append(sea)
	cur_season = game_seasons[0]
	cur_season_ind = 0
	print("Turn Manager | Setup | Starting Season: " + str(Season.keys()[cur_season]))
	print("Turn Manager | Setup | Game Season Order: " + str(get_season_order_names()))
	season_order_generated.emit()


func int_to_game_phase(phase: int) -> String:
	for name in GameLoop.keys():
		if GameLoop[name] == phase:
			return name
	return "UNKNOWN"

#endregion

#region Public API
func progress_turn():
	if game_phase >= (GameLoop.size() -1 ):
		game_phase = GameLoop.values()[0] # Set turn to Upkeep
		progress_turn_order()
	else:
		game_phase = GameLoop.values()[game_phase + 1]
	game_phased_changed.emit(game_phase)

	# After progressin turn, check in admin_phase. If so, the auto run it.
	if game_phase in admin_game_phases:
		progress_turn()


func progress_turn_order():
	var active_actor_ind:int = _get_indx(active_actor, turn_order)
	# If it was the last self_player in the turn order loop back to the start
	if(active_actor_ind == turn_order.size()-1):
		turn_number =+ 1
		active_actor = turn_order[0]

		# Since its the last self_player looping to the 1st,
		# All code for starting a new round goes here too ....
		# Should probs be a func() call but ...

		progress_season()

	else:
		active_actor = turn_order[(active_actor_ind + 1)]
	print(active_actor.name)
	actor_turn_changed.emit(active_actor)


func progress_season():
	if(cur_season_ind == game_seasons.size()-1):
		cur_season_ind = 0
	else:
		cur_season_ind =+ 1
	cur_season = game_seasons[cur_season_ind]	
	print("Turn manager | Round update | Current season: " + str(Season.keys()[cur_season]))
	season_changed.emit(cur_season_ind)

#endregion

#region State Queries
func get_game_state() -> GameSequence:
	return game_state
func set_game_state(state: GameSequence):
	self.game_state = state
	current_game_state.emit(game_state)


func get_game_phase() -> GameLoop:
	return game_phase
func set_game_phase(phase: GameLoop):
	self.game_phase = phase


func get_combat_phase() -> CombatLoop:
	return combat_phase
func set_combat_phase(phase: CombatLoop):
	self.combat_phase = phase


func get_turn_order() -> Array[Actor]:
	return turn_order
func get_turn_order_names() -> Array[String]:
	var turn_names: Array[String]
	for actor in turn_order:
		turn_names.append(actor.name)
	return turn_names


func get_season_order() -> Array[Season]:
	return game_seasons
func get_season_order_names() -> Array[String]:
	var season_names: Array[String]
	for sea in game_seasons:
		season_names.append(Season.keys()[sea])
	return season_names
func get_season(sea: String) -> Variant:
	for i in range(Season.keys().size()):
		if Season.keys()[i] == sea:
			return Season.values()[i]
	return null


func get_active_actor() -> Actor:
	return active_actor


func get_admin_phases() -> Array:
	return admin_game_phases


func get_non_skipable_phases() -> Array:
	return non_skipable_phases


func get_debug_dict() -> Dictionary:
	var dict: Dictionary = {
		"game_state" : game_state,
		"game_phase" : game_phase,
		"combat_phase" : combat_phase,
		"turn_order" : get_turn_order_names(),
		"active_actor" : active_actor,
		"turn_number" : turn_number,
		"game_seasons" : game_seasons,
		"cur_season" : cur_season,
	}
	return dict


func get_season_color(sea: Season) -> Color:
	return SEASON_COLORS[sea]
#endregion

#region Callbacks
func combat_started(contest: Contest):
	# print("Turn Manager | Recieved start Combat Req")
	set_combat_phase(CombatLoop.ASSIGN_COMBATANTS)
	combat_assign.emit(contest)


func actor_finished_setup(a: Actor):
	if game_state == GameSequence.SETUP:
		await get_tree().process_frame
		self.set_game_state(GameSequence.GAME_LOOP)
		self.progress_turn()


#endregion

#region Helpers
func _get_indx(value, array: Array) -> int:
	for i in range(array.size()):
		if array[i] == value:
			return i
	return -1


#endregion

# End Of File