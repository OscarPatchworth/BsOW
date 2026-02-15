extends GameManager

#signals
signal built_action_completed(req: Action)
signal buy_unit_action_completed(req: Action)

# enums

# constants
const LANDER_RADIUS:float = 1
const MIN_DIST_BETWEEN_LANDERS = 2
const MIN_DIST_SQUARED = MIN_DIST_BETWEEN_LANDERS ** 2
const FLOOR_OFFSET:Vector3 = Vector3.UP * 2

# static variables
var landers_sence_node: Node3D

# @export variables
@export var lander_sence: PackedScene
@export var biome_types: Array[BiomeData]

@export var connected_lander_distance: float:
	set(value):
		connected_distance_sq = value ** 2

# remaining regular variables
var landers:Array[Lander]
var connected_distance_sq: float = 0.0

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


func is_pos_min_distance_apart(pos: Vector3) -> bool:
	# Here using the LANDER_RADIUS as the min distance between landers
	# Squaring this value to make it compariable to the squared distance between lander positions
	# Using the distanced_squared_to over distance_to bcs its operationally faster
	for lander in landers:
		if (pos.distance_squared_to(lander.position) < MIN_DIST_SQUARED):
			return false
	return true


func get_connected_landers(target_lander: Lander) -> Array[Lander]:
	var connected_landers: Array[Lander] = []
	for lander in landers:
		if (target_lander.position.distance_squared_to(lander.position) < connected_distance_sq):
			if(lander != target_lander):
				connected_landers.append(lander)
	return connected_landers


func get_lander_occpied_actor(target: Lander) -> Actor:
	var target_units = target.get_units()
	if target_units != []:
		return target_units[0].get_owned_by()
	else:
		return null


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
