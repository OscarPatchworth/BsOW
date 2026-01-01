extends GameManager

#signals

# enums

# constants
const lander_radius:float = 1

# static variables

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods


### Calls
func is_lander_placeable(req_pos) -> bool:
	if req_pos != Vector3.ZERO:
		return true
	else:
		return false