#turn_manager.gd
extends GameManager

# signals
signal game_phased_changed(game_phase: GameLoop)
signal combat_assign(contest: Contest)
signal turn_phase_updated(phase: GameLoop)
signal turn_order_generated
signal actor_turn_changed(active: Actor)

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

# constants

# static variables

# @export variables

# remaining regular variables
var game_state: Gamesequence = Gamesequence.GAME_LOOP
var game_phase: GameLoop = GameLoop.UPKEEP
var combat_phase: CombatLoop = CombatLoop.MOVE_UNITS 
var turn_order: Array[Actor]
var active_actor: Actor
var turn_number: int = 1

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


func init_turn_order():
	turn_order.shuffle()
	print(turn_order)
	active_actor = turn_order[0]
	turn_order_generated.emit()
	actor_turn_changed.emit(turn_order[0])


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
	if(active_actor_ind == turn_order.size()-1):
		turn_number =+ 1
		active_actor = turn_order[0]
	else:
		active_actor = turn_order[(active_actor_ind + 1)]
	print(active_actor.name)
	actor_turn_changed.emit(active_actor)


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


func get_turn_dict() -> Dictionary:
	var dict: Dictionary = {
		"game_state" : game_state,
		"game_phase" : game_phase,
		"combat_phase" : combat_phase,
		"turn_order" : get_turn_order_names()
		#"active_actor" : active_actor
	}

	return dict

func int_to_game_phase(phase: int) -> String:
	for name in GameLoop.keys():
		if GameLoop[name] == phase:
			return name
	return "UNKNOWN"
### Connected Signals
