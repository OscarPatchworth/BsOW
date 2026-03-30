extends GameManager

# signals
signal build_action(req)
signal buy_unit_action(req)
signal progress_turn

# enums

# constants

# static variables
var movement_ctrl = load("res://logic/managers_and_systems/movement_controler.gd")
var lander_manager: GameManager
var turn_manager: GameManager
var combat_manager: GameManager

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
		Action.RequestType.ATTACK:
			#print("Attack Action Recieved! ")
			handle_attack(req)
		Action.RequestType.BUY:
			pass
		Action.RequestType.BUY_BUILDING:
			handle_buy_building(req)
		Action.RequestType.BUY_UNIT:
			handle_buy_unit(req)
		Action.RequestType.PROGRESS_TURN:
			#print("Action Manager | Req Recieved | Next Phase")
			handle_progress_turn(req)
			pass
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
	# Check if(lander.units.owner == player)
	var target_lander_owner = lander_manager.get_lander_occpied_actor(req.target_lander)
	if(target_lander_owner == null or target_lander_owner == req.actor):
		print("Can move landers to target")
	else:
		print("Target Lander is hostile land \n Movement failed")
		return

	lander_manager.move_units_action(req)


func handle_attack(req: Action):
	# Check if selected & target lander have enemy units
	if(req.selected_lander.get_units() == []):
		print("Action Manager Error | Attack Req: Selected lander has no units! ")
		return
	if(req.target_lander.get_units() == []):
		print("Action Manager Error | Attack Req: Target lander has no units! ")
		return
	if(req.selected_lander.get_units()[0].get_owned_by() == req.target_lander.get_units()[0].get_owned_by()):
		print("Action Manager Error | Attack Req: Selected and Target landers are allies")
		return
	# Check if the attacking units belong to the attacking player
	if(req.selected_lander.get_units()[0].get_owned_by() != req.actor):
		print("Action Manager Error | Attack Req: Attacking force doese not belong to the attacking player")
		return
	# Fwd the attack to combat manager
	print("Fwd attack req")
	combat_manager.attack_action(req)


func handle_progress_turn(req: Action):
	#if req.actor != turn_manager.get_active_player():
		#print("Turn Manager | Err |")
	#else:
	progress_turn.emit()
