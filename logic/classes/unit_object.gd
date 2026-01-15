#unit_object.gd
class_name UnitObject
extends Node

# signals

# enums

# constants

# static variables
var unit_data: UnitData

# @export variables

# remaining regular variables
var hit_points: int = 1

# @onready variables

###################################################################################################
###	Methods


### Connected Signals


## Calls
func setup(unit_type: UnitData):
	self.unit_data = unit_type


## Get/Set (er)s
func get_unit_data() -> UnitData:
	return unit_data
func set_unit_data(unit: UnitData):
	self.unit_data = unit


### Connected Signals