#turn_manager.gd
extends GameManager

# signals
signal game_phased_changed(game_phase: GameLoop)
signal combat_assign(contest: Contest)
signal turn_phase_updated(phase: GameLoop)
signal turn_order_generated
signal actor_turn_changed(active: Actor)
signal season_order_generated
signal season_changed(sea_indx: int)

# enums
enum Gamesequence {
	SETUP,
	GAME_LOOP,
	CLEANUP
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

# constants

const SEASON_COLORS := {
	Season.SPRING: Color("#32a832"),
	Season.SUMMER: Color("#9e4266"),
	Season.AUTUMN: Color("#a16a33"),
	Season.WINTER: Color("#2a4d5e"),
}


# static variables

# @export variables

# remaining regular variables
var game_state: Gamesequence = Gamesequence.GAME_LOOP
var game_phase: GameLoop = GameLoop.UPKEEP
var combat_phase: CombatLoop = CombatLoop.MOVE_UNITS 
var turn_order: Array[Actor]
var active_actor: Actor
var turn_number: int = 1
var game_seasons: Array[Season]
var cur_season: Season
var cur_season_ind: int

# @onready variables

###################################################################################################
###	Methods
func get_indx(value, array: Array) -> int:
	for i in range(array.size()):
		if array[i] == value:
			return i
	return -1

### Connected Signals


## Calls
func bind_actor_to_actor_group(a: Actor):
	if not a in turn_order:
		turn_order.append(a)


func self_init():
	init_turn_order()
	init_season()


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

func combat_started(contest: Contest):
	# print("Turn Manager | Recieved start Combat Req")
	set_combat_phase(CombatLoop.ASSIGN_COMBATANTS)
	combat_assign.emit(contest)


func progress_turn():
	if game_phase >= (GameLoop.size() -1 ):
		game_phase = GameLoop.values()[0]
		progress_turn_order()
	else:
		game_phase = GameLoop.values()[game_phase + 1]
	game_phased_changed.emit(game_phase)


func progress_turn_order():
	var active_actor_ind:int = get_indx(active_actor, turn_order)
	# If it was the last player in the turn order loop back to the start
	if(active_actor_ind == turn_order.size()-1):
		turn_number =+ 1
		active_actor = turn_order[0]

		# Since its the last player looping to the 1st,
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
		cur_season_ind += 1
	cur_season = game_seasons[cur_season_ind]	
	print("Turn manager | Round update | Current season: " + str(Season.keys()[cur_season]))
	season_changed.emit(cur_season_ind)


## Get/Set (er)s
func get_game_state() -> Gamesequence:
	return game_state
func set_game_state(state: Gamesequence):
	self.game_state = state
	game_phased_changed.emit(game_phase)


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


func get_turn_dict() -> Dictionary:
	var dict: Dictionary = {
		"game_state" : game_state,
		"game_phase" : game_phase,
		"combat_phase" : combat_phase,
		"turn_order" : get_turn_order_names()
		#"active_actor" : active_actor
	}
	return dict


func get_season_color(sea: Season) -> Color:
	return SEASON_COLORS[sea]


func int_to_game_phase(phase: int) -> String:
	for name in GameLoop.keys():
		if GameLoop[name] == phase:
			return name
	return "UNKNOWN"
### Connected Signals
