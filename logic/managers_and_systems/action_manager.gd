extends GameManager

# signals
signal build_action(req)

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
		Action.RequestType.BUY_BUILDING:
			handle_buy_building(req)
		_:
			print("No Action Match type match!! \n match type: " + str(Action.RequestType.keys()[req.type] ))


func handle_place_lander(req: Action):
	if(lander_manager.is_valid_lander_placement(req.position)):
		lander_manager.inst_lander(req.position)
	else:
		print("Invalid Place Lander Request")


func handle_buy_building(req:Action):
	#print("Action recieved: " + str(req.get_action_dict()))
	## Check if valid
	if(req.target_lander.has_building):
		print("Can't build on lander: Building already present")
		pass
	## Then emit if true
	build_action.emit(req)
