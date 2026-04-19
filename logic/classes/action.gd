class_name Action
extends Node

# signals

# enums
enum RequestType {
	MOVEMENT, 
	ATTACK,
	BUY,
	PLACE_LANDER,
	PLACE_BUILDING,
	BUY_UNIT,
	PROGRESS_TURN,
	PLACE_BIOME
}

# constants

# static variables
var type: RequestType
var actor: Actor
var position: Vector3
var target_lander: Lander
var building_type: BuildingData
var unit_type: UnitData
var selected_lander: Lander
var selected_units: Array[UnitObject]
var purchasable
var biome_type: BiomeData

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


# Selected Lander
func get_selected_lander() -> Lander:
	return selected_lander
func set_selected_lander(selected: Lander):
	selected_lander = selected


# Building Type
func get_building_type() -> BuildingData:
	return building_type
func set_building_type(building_data):
	self.building_type = building_data


# Unit Type
func get_unit_type() -> UnitData:
	return unit_type
func set_unit_type(unit_data: UnitData):
	self.unit_type = unit_data


# Selected Units
func get_selected_units() -> Array[UnitObject]:
	return selected_units
func set_selected_units(units: Array[UnitObject]):
	selected_units = units


# Purchasables
func get_purchasable():
	return purchasable
func set_purchasable(item):
	purchasable = item


# BiomeType
func get_biome_type() -> BiomeData:
	return biome_type
func set_biome_type(b: BiomeData):
	biome_type = b


# All
func get_action_dict() -> Dictionary:
	var build_name: String = str(null)
	if(building_type):
		build_name = building_type.get_building_name()

	var unit_name: String = str(null)
	if(unit_type):
		unit_name = unit_type.get_unit_name()

	var all = {
		"type": RequestType.find_key(type),
		"actor": actor.name,
		"pos": position,
		"target lander" :  target_lander.get_biome().name if target_lander else "",
		"building type" : build_name,
		"unit_type" : unit_name,
		"selected_lander" : selected_lander.get_biome().name if selected_lander else "",
		"purchasable" : purchasable.name,
		"biome_type" : biome_type.name,
	}
	return all
