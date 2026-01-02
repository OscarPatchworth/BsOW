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
	if(lander_manager.is_valid_lander_placement(req.position)):
		lander_manager.inst_lander(req.position)
	else:
		print("Invalid Place Lander Request")
