class_name Action
extends Node

# signals

# enums
enum RequestType {
	MOVEMENT, 
	ATTACK,
	BUY,
	PLACE_LANDER,
	BUY_BUILDING,
	BUY_UNIT
}

# constants

# static variables
var type: RequestType
var actor: Actor
var position: Vector3
var target_lander: Lander
var building_type: BuildingData
var unit_type: UnitData

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


# Building Type
func get_building_type() -> BuildingData:
	return building_type
func set_building_type(building_data):
	self.building_type = building_data


# All
func get_action_dict() -> Dictionary:
	var build_name: String = str(null)
	if(building_type):
		build_name = building_type.get_building_name()

	var unit_name: String = str(null)
	if(unit_type):
		unit_name = unit_type.get_unit_name()

	var all = {
		"type": type,
		"actor": actor,
		"pos": position,
		"target lander" : target_lander,
		"building type" : build_name,
		"unit_type" : unit_name
	}
	return all
