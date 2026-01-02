class_name Action
extends Node

# signals

# enums
enum RequestType {
	MOVEMENT, 
	ATTACK,
	BUY,
	PLACE_LANDER,
}

# constants

# static variables
var type: RequestType
var actor: Actor
var position: Vector3
var target_lander: Lander

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods


### Get/Set (ers)
# Type
func get_type() -> RequestType:
	return self.type
func set_type(req_type: RequestType):
	self.type = req_type

# Actor
func get_actor() -> Actor:
	return self.actor
func set_actor(req_actor: Actor):
	self.actor = req_actor

# Pos
func get_pos() -> Vector3:
	return position
func set_pos(req_pos: Vector3):
	self.position = req_pos


# Target Lander
func get_target_lander() -> Lander:
	return target_lander
func set_target_lander(target: Lander):
	self.target_lander = target


# All
func get_action_dict() -> Dictionary:
	var all = {
		"type": type,
		"actor": actor,
		"pos": position,
		"target" : target_lander
	}
	return all
