extends GameManager

#signals

# enums

# constants
const LANDER_RADIUS:float = 1

# static variables
var landers_sence_node: Node3D

# @export variables
@export var lander_sence: PackedScene

# remaining regular variables
var landers:Array[Lander]

# @onready variables

###################################################################################################
###	Methods
func inst_lander(pos: Vector3):
	var new_lander = lander_sence.instantiate()
	new_lander.position = pos
	landers_sence_node.add_child(new_lander)

### Calls
func is_lander_placeable(req_pos) -> bool:
	if req_pos != Vector3.ZERO:
		return true
	else:
		return false