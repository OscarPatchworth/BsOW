#unit_object.gd
class_name UnitObject
extends Node

# signals

# enums

# constants

# static variables
var unit_data: UnitData
var ownned_by: Actor

# @export variables

# remaining regular variables
var hit_points: int = 1

# @onready variables

###################################################################################################
###	Methods


### Connected Signals


## Calls
func setup(unit_type: UnitData, ownr: Actor):
	self.unit_data = unit_type
	self.ownned_by = ownr


## Get/Set (er)s
func get_unit_data() -> UnitData:
	return unit_data
func set_unit_data(unit: UnitData):
	self.unit_data = unit


func get_owned_by() -> Actor:
	return ownned_by
func set_ownned_by(target: Actor):
	ownned_by = target

func has_purchases() -> bool:
	return false
func get_purchases() -> Dictionary:
	return {}



### Connected Signals