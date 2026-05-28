#contest.gd
class_name Contest
#extends Node

# signals

# enums

# constants

# static variables

# @export variables

# remaining regular variables
var contested_lander: Lander
var origin_lander: Lander

var origin_units: Array[UnitObject] = []
var target_units: Array[UnitObject] = []

#var origin_abilities: Array[AbbilityInstance] = []
#var target_abilities: Array[AbbilityInstance] = []

var origin_ready: bool = false
var target_ready: bool = false

# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()

### Connected Signals

## Calls
func add_origin_unit(unit: UnitObject):
	origin_units.append(unit)
func rmv_origin_unit(unit: UnitObject):
	origin_units.erase(unit)


func add_target_unit(unit: UnitObject):
	target_units.append(unit)
func rmv_target_unit(unit: UnitObject):
	target_units.erase(unit)


## Get/Set (er)s
func get_contested_lander() -> Lander:
	return contested_lander
func set_contested_lander(lnd: Lander):
	contested_lander = lnd


func get_origin_lander() -> Lander:
	return origin_lander
func set_origin_lander(lnd: Lander):
	origin_lander = lnd


func get_origin_units() -> Array[UnitObject]:
	return origin_units
func set_invadining_units(units: Array[UnitObject]):
	origin_units = units


func get_target_units() -> Array[UnitObject]:
	return target_units
func set_target_units(units: Array[UnitObject]):
	target_units = units


func get_origin_actor() -> Actor:
	return origin_lander.get_units()[0].get_owned_by()
func get_target_actor() -> Actor:
	return contested_lander.get_units()[0].get_owned_by()


func get_origin_ready() -> bool:
	return origin_ready
func set_origin_ready(ready: bool):
	origin_ready = ready


func get_target_ready() -> bool:
	return target_ready
func set_target_ready(ready: bool):
	target_ready = ready


func get_dict() -> Dictionary:
	var dict = {
	"contested_lander" : contested_lander,
	"origin_lander" : origin_lander,
	"origin_units" : origin_units,
	"target_units" : target_units,
	"origin_ready" : origin_ready,
	"target_ready" : target_ready
	}

	return dict

### Connected Signals
