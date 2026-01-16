#turn_manager.gd
extends GameManager

# signals

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
	REINFORCEMENT_PHASE,
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

# @onready variables

###################################################################################################
###	Methods


### Connected Signals


## Calls

## Get/Set (er)s
func get_game_state() -> Gamesequence:
	return game_state
func set_game_state(state: Gamesequence):
	self.game_state = state


func get_game_phase() -> GameLoop:
	return game_phase
func set_game_phase(phase: GameLoop):
	self.game_phase = phase


func get_combat_phase() -> CombatLoop:
	return combat_phase
func set_combat_phase(phase: CombatLoop):
	self.combat_phase = phase

### Connected Signals