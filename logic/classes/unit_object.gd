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
	


### Connected Signals