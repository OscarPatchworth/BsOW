class_name Actor
extends Node

# enums
enum CombatSide {
	ATTAKING,
	DEFENDING
}

# constants
#const MAX_SPEED = 200

# static variables
var species: SpeciesData
var turn_manager: TurnManager
var lander_manager: LanderManager
var combat_manager: CombatManager

# @export variables

# remaining regular variables
var combat_pos # Combat ATK/DEF
var wallet: EconData

###################################################################################################
# Methods



# Calls
func combat_req(contest: Contest):
	#print("Player | Contest Lander call recieved")

	# Check if this combat involves this self_player
	if(contest.get_invading_actor() == self or contest.get_defending_actor() == self):
		combat_pos = CombatSide.ATTAKING if contest.get_invading_actor() == self else CombatSide.DEFENDING
		enter_combat(contest)
		
	else:
		# Player is not involved in combat
		# Do not need to do anything
		# May want to put self_player in spectator mode or smth later
		pass


func enter_combat(contest: Contest):
	pass


## Get/Set (er)s
func get_species() -> SpeciesData:
	return species
func set_species(s: SpeciesData):
	species = s

func get_wallet() -> EconData:
	return wallet