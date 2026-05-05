#lander_manager.gd
#class_name LanderManager
#extends Node

#signals
signal built_action_completed(req: Action)
signal buy_unit_action_completed(req: Action)
signal move_units_action_completed(req: Action)
signal completed_upkeep()

# enums

# constants
const LANDER_RADIUS:float = 1
const MIN_DIST_BETWEEN_LANDERS = 2
const MIN_DIST_SQUARED = MIN_DIST_BETWEEN_LANDERS ** 2
const FLOOR_OFFSET:Vector3 = Vector3.UP

# static variables
var landers_sence_node: Node3D
var lander_sence: PackedScene
var biome_types: Array[BiomeData]
var connected_lander_distance: float

# @export variables

# remaining regular variables
var landers:Array[Lander]

# @onready variables

###################################################################################################
###	Methods
func inst_lander(pos: Vector3):
	var new_lander = lander_sence.instantiate()
	#Acidental Feature:
	#	Meant to have the lander slightly off the ground to prevent wobbling
	#	Now has the lander fall to the ground when spawned	
	new_lander.position = pos + FLOOR_OFFSET

	wire_and_signal_lander(new_lander)

	new_lander.set_biome(biome_types.pick_random())
	landers_sence_node.add_child(new_lander)
	landers.append(new_lander)


func inst_biome(req: Action):
	var new_lander = lander_sence.instantiate()
	#Acidental Feature:
	#	Meant to have the lander slightly off the ground to prevent wobbling
	#	Now has the lander fall to the ground when spawned	
	new_lander.position = req.get_pos() + FLOOR_OFFSET

	wire_and_signal_lander(new_lander)

	new_lander.set_biome(req.get_biome_type())
	landers_sence_node.add_child(new_lander)
	landers.append(new_lander)


func spawn_protected_lander(pos: Vector3, ownr: Actor, amount_defenders: int):
	inst_lander(pos)
	#cmd ^ adds lander to end of landers[] and so below grabs the lander that was just instanced
	var target = landers[-1]

	#Get footsolider
	for unit in ownr.species.units:
		if (unit.base != null and unit.base.name == "Base Footsolider"):
			for i in amount_defenders:
				var footsoldier = UnitObject.new()
				footsoldier.setup(unit, ownr)

				var defending_units: Array[UnitObject]
				defending_units.append(footsoldier)

				target.add_units(defending_units)
		else:
			print("Failed to spawn troops on protected lander. \n error: species has no units with base of \'Base Footsolider\'")

func is_pos_min_distance_apart(pos: Vector3) -> bool:
	# Here using the LANDER_RADIUS as the min distance between landers
	# Squaring this value to make it compariable to the squared distance between lander positions
	# Using the distanced_squared_to over distance_to bcs its operationally faster
	for lander in landers:
		if (pos.distance_squared_to(lander.position) < MIN_DIST_SQUARED):
			return false
	return true


func is_pos_lander_adjacent(pos: Vector3) -> bool:
	for lander in landers:
		if (pos.distance_to(lander.position) < connected_lander_distance):
			return true
	return false


func get_connected_landers(target_lander: Lander) -> Array[Lander]:
	var connected_landers: Array[Lander] = []
	for lander in landers:
		if (target_lander.global_position.distance_to(lander.global_position) < connected_lander_distance):
			if(lander != target_lander):
				connected_landers.append(lander)
		print(target_lander.position.distance_to(lander.position) )
	return connected_landers


func get_lander_occpied_actor(target: Lander) -> Actor:
	return target.get_ownr()


func get_landers_actor_has(a: Actor) -> Array:
	var return_landers = landers.map(func(lnd): if get_lander_occpied_actor(lnd) == a: return lnd )
	return return_landers.filter(func(lnd): return bool(lnd != null))


### Wires and Signals
func wire_and_signal_lander(lander: Lander):
	lander.built_action_completed.connect(self.fwd_build_action_completed)
	lander.buy_unit_action_completed.connect(self.fwd_buy_unit_action_completed)

func fwd_build_action_completed(req: Action):
	built_action_completed.emit(req)


func fwd_buy_unit_action_completed(req: Action):
	buy_unit_action_completed.emit(req)

### Calls
func is_valid_lander_placement(req_pos: Vector3) -> bool:
	return is_pos_min_distance_apart(req_pos)


func build_action(req: Action):
	req.get_target_lander().build_action(req)


func buy_unit_action(req: Action):
	req.get_target_lander().buy_unit_action(req)


func move_units_action(req: Action):
	# lander1.rvm(units)
	req.selected_lander.rmv_units(req.selected_units)
	# lander2.add(units)
	req.target_lander.add_units(req.selected_units)
	# Emit confirmation
	move_units_action_completed.emit(req)


func run_upkeep(who: Actor):
	var ply_wallet = who.get_wallet()
	for lander in get_landers_actor_has(who):
		ply_wallet.add_resource(lander.get_upkeep_econ())
	completed_upkeep.emit()
