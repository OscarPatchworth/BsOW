#building_object.gd
class_name BuildingObject
extends Node

# signals

# enums

# constants

# static variables
var building_data: BuildingData

# @export variables

# remaining regular variables
var hit_points: int = 1

# @onready variables

###################################################################################################
###	Methods


### Connected Signals


## Calls
func setup(building_type: BuildingData):
	building_data = building_type


### Connected Signals