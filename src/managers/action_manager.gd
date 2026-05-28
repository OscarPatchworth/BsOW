# action_manager.gd
# Takes all actor requests and checks if its allowed by the rules. On true it forwards it to the correct manager.

class_name ActionManager
extends Node

#region Signals
signal build_action(req)
signal buy_unit_action(req)
signal progress_turn
signal place_biome(req)
#endregion

#region Runtime Refs
var lander_manager: Node
var turn_manager: Node
var combat_manager: Node
#endregion

###################################################################################################
#region Lifecycle
#endregion

#region Public API
func action_request(req: Action):
	match req.type:
		Action.RequestType.PLACE_LANDER:
			handle_place_lander(req)
		Action.RequestType.MOVEMENT:
			handle_movement(req)
		Action.RequestType.ATTACK:
			handle_attack(req)
		Action.RequestType.BUY:
			handle_buy(req)
		Action.RequestType.PLACE_BUILDING:
			handle_place_building(req)
		Action.RequestType.BUY_UNIT:
			handle_buy_unit(req)
		Action.RequestType.PROGRESS_TURN:
			handle_progress_turn(req)
		Action.RequestType.PLACE_BIOME:
			handle_place_biome(req)
		_:
			print("No Action match type: " + str(Action.RequestType.keys()[req.type]))
#endregion

#region Validation
func can_place_lander(req: Action) -> bool:
	return lander_manager.is_valid_lander_placement(req.position)

func can_buy_unit(req: Action) -> bool:
	if req.get_target_lander() == null:
		print("Buy Unit Req is missing target lander")
		return false
	if req.target_lander.get_building_data() == null:
		print("Buy Unit Req is missing spawning building")
		return false
	var b = req.target_lander.get_building_data()
	if not b.get_can_spawn():
		print("Buy Unit Req failed: building cannot spawn units")
		return false
	if req.unit_type.get_type() not in b.get_spawn_type():
		print("Buy Unit Req failed: building cannot spawn this unit type")
		return false
	return true
#endregion

#region Action Handlers
func handle_place_lander(req: Action):
	if can_place_lander(req):
		lander_manager.inst_lander(req.position)
		progress_turn.emit()
	else:
		print("Invalid Place Lander Request")

func handle_place_building(req: Action):
	if req.target_lander.has_building:
		print("Can't build on lander: Building already present")
		return
	build_action.emit(req)

func handle_buy_unit(req: Action):
	if can_buy_unit(req):
		buy_unit_action.emit(req)

func handle_movement(req: Action):
	var target_lander_owner = lander_manager.get_lander_occpied_actor(req.target_lander)
	if target_lander_owner == null or target_lander_owner == req.actor:
		lander_manager.move_units_action(req)
	else:
		print("Target Lander is hostile land")
		return

func handle_attack(req: Action):
	if req.origin_lander.get_units() == []:
		print("Selected lander has no units")
		return
	if req.target_lander.get_units() == []:
		print("Target lander has no units")
		return
	if req.origin_lander.get_units()[0].get_owned_by() == req.target_lander.get_units()[0].get_owned_by():
		print("Selected and target landers are allies")
		return
	if req.origin_lander.get_units()[0].get_owned_by() != req.actor:
		print("ORIGIN force does not belong to actor")
		return
	combat_manager.attack_action(req)

func handle_progress_turn(req: Action):
	if turn_manager.get_game_phase() in turn_manager.get_admin_phases():
		print("Actor attempting to progress admin phase")
		return
	if turn_manager.get_game_phase() in turn_manager.get_non_skipable_phases():
		print("Actor attempting to progress non-skipable phase")
	progress_turn.emit()

func handle_buy(req: Action):
	if req.get_purchasable() is BuildingData:
		_handle_buy_building(req)
	elif req.get_purchasable() is UnitData:
		_handle_buy_unit(req)
	else:
		print("Purchasable is not a valid type")

func handle_place_biome(req: Action):
	if can_place_lander(req):
		place_biome.emit(req)
	else:
		print("Invalid Place Biome Request")
#endregion

#region Helpers
func _handle_buy_building(req: Action):
	var ply_wallet: EconData = req.actor.get_wallet()
	if not req.purchasable.get_cost().cost_less_than(ply_wallet):
		print("Actor cannot afford building")
		return
	if req.origin_lander.get_building() != null:
		print("Lander already has building")
		return
	ply_wallet.rmv_resource(req.purchasable.get_cost())
	req.origin_lander.build_action(req)

func _handle_buy_unit(req: Action):
	var ply_wallet: EconData = req.actor.get_wallet()
	if not req.purchasable.get_cost().cost_less_than(ply_wallet):
		print("Actor cannot afford unit")
		return
	ply_wallet.rmv_resource(req.purchasable.get_cost())
	req.origin_lander.buy_unit_action(req)
#endregion

# End Of File
