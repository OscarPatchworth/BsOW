extends GameManager

# signals

# enums

# constants

# static variables
var movement_ctrl = load("res://logic/managers_and_systems/movement_controler.gd")
var lander_manager: GameManager
# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods

func action_request(req: Action):
	match req.type:
		Action.RequestType.PLACE_LANDER:
			handle_place_lander(req)
		Action.RequestType.MOVEMENT:
			pass
		Action.RequestType.ATTACK:
			pass
		Action.RequestType.BUY:
			pass
	pass

func handle_place_lander(req: Action):
	print(str(req.actor.name) + " | " + str(req.position))
	if(lander_manager.is_pos_min_dist_from_landers(req.position) == true):
		print("Valid Place Lander Req")
	else:
		print("Invalid Place Lander Req")
