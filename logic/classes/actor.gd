class_name Actor
extends Node

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var species: SpeciesData
var turn_manager: GameManager
var lander_manager: GameManager
var combat_manager: GameManager

# @export variables

# remaining regular variables
var cmb_pos # Combat ATK/DEF

###################################################################################################
# Methods



# Calls
func combat_req(contest: Contest):
	#print("Player | Contest Lander call recieved")

	# Check if this combat involves this player
	if(contest.get_invading_actor() == self or contest.get_defending_actor() == self):
		cmb_pos = "Attacker" if contest.get_invading_actor() == self else "Defender"
		enter_combat(contest)
		
	else:
		# Player is not involved in combat
		# Do not need to do anything
		# May want to put player in spectator mode or smth later
		pass


func enter_combat(contest: Contest):
	pass
