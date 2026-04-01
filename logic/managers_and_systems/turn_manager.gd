#turn_manager.gd
extends GameManager

# signals
signal game_phased_changed(game_phase: GameLoop)
signal combat_assign(contest: Contest)
signal turn_phase_updated(phase: GameLoop)

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
var actor_group: Array[Actor]
#var active_actor: Actor

# @onready variables

###################################################################################################
###	Methods


### Connected Signals


## Calls
func bind_actor_to_actor_group(a: Actor):
	if not a in actor_group:
		actor_group.append(a)


func init_turn_order():
	actor_group.shuffle()
	var turn_order: Array[String]
	for actor in actor_group:
		turn_order.append(actor.name)
	print(turn_order)


func combat_started(contest: Contest):
	# print("Turn Manager | Recieved start Combat Req")
	set_combat_phase(CombatLoop.ASSIGN_COMBATANTS)
	combat_assign.emit(contest)


func progress_turn():
	if game_phase >= (GameLoop.size() -1 ):
		game_phase = GameLoop.values()[0]
	else:
		game_phase = GameLoop.values()[game_phase + 1]
	game_phased_changed.emit(game_phase)



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


func get_turn_dict() -> Dictionary:
	var dict: Dictionary = {
		"game_state" : game_state,
		"game_phase" : game_phase,
		"combat_phase" : combat_phase,
		#"active_actor" : active_actor
	}

	return dict

func int_to_game_phase(phase: int) -> String:
	for name in GameLoop.keys():
		if GameLoop[name] == phase:
			return name
	return "UNKNOWN"
### Connected Signals
