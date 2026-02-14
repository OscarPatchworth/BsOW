extends GameManager

# signals
signal build_action(req)
signal buy_unit_action(req)

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
			handle_movement(req)
			pass
		Action.RequestType.ATTACK:
			pass
		Action.RequestType.BUY:
			pass
		Action.RequestType.BUY_BUILDING:
			handle_buy_building(req)
		Action.RequestType.BUY_UNIT:
			handle_buy_unit(req)
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
		return
	## Then emit if true
	build_action.emit(req)


func handle_buy_unit(req:Action):
	#print("Action Recieved: " + str(req.get_action_dict()))
	## Check if valid
	if(req.get_target_lander() == null):
		print("Buy Unit Req is missing target lander")
		return
	if(req.target_lander.get_building_data() == null):
		print("Buy Unit Req is missing spawning building")
		return
	var lander_building = req.target_lander.get_building_data()
	if(!lander_building.get_can_spawn()):
		print("Buy Unit Req failed: The building \'" + str(lander_building.get_building_name() + "\' can not spawn units"))
		return
	if(req.unit_type.get_type() not in lander_building.get_spawn_type() ):
		print("Buy Unit Req failed: \'" + str(lander_building.get_building_name()) + "\' can not spawn this type of unit: \'" + str(req.unit_type.get_type()) + "\'")
		return
	#print("Buy unit req valid")
	buy_unit_action.emit(req)


func handle_movement(req:Action):
	print("Movement Action Recieved")
	print(req.get_action_dict())
	# Check if(lander.units.owner == player)
	#lander_owner = lander_manager.get_lander_occpied_actor(req.)
		#lander1.rvm(units)
		#lander2.add(units)
