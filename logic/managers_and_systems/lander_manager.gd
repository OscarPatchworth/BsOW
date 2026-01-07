extends GameManager

#signals

# enums

# constants
const LANDER_RADIUS:float = 1
const MIN_DIST_BETWEEN_LANDERS = 2
const MIN_DIST_SQUARED = MIN_DIST_BETWEEN_LANDERS ** 2

# static variables
var landers_sence_node: Node3D

# @export variables
@export var lander_sence: PackedScene
@export var biome_types: Array[BiomeData]

# remaining regular variables
var landers:Array[Lander]

# @onready variables

###################################################################################################
###	Methods
func inst_lander(pos: Vector3):
	var new_lander = lander_sence.instantiate()
	new_lander.position = pos
	new_lander.biome = biome_types.pick_random()
	
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


### Calls
func is_valid_lander_placement(req_pos: Vector3) -> bool:
	return is_pos_min_distance_apart(req_pos)
