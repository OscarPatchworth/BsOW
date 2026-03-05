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
var invading_lander: Lander

var invading_units: Array[UnitObject] = []
var defending_units: Array[UnitObject] = []

#var invading_abilities: Array[AbbilityInstance] = []
#var defending_abilities: Array[AbbilityInstance] = []

var invading_ready: bool = false
var defending_ready: bool = false

# @onready variables

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()

### Connected Signals

## Calls
func add_invading_unit(unit: UnitObject):
	invading_units.append(unit)
func rmv_invading_unit(unit: UnitObject):
	invading_units.erase(unit)


## Get/Set (er)s
func get_contested_lander() -> Lander:
	return contested_lander
func set_contested_lander(lnd: Lander):
	contested_lander = lnd


func get_invading_lander() -> Lander:
	return invading_lander
func set_invading_lander(lnd: Lander):
	invading_lander = lnd


func get_invading_units() -> Array[UnitObject]:
	return invading_units
func set_invadining_units(units: Array[UnitObject]):
	invading_units = units


func get_defending_units() -> Array[UnitObject]:
	return defending_units
func set_defending_units(units: Array[UnitObject]):
	defending_units = units


func get_invading_actor() -> Actor:
	return invading_lander.get_units()[0].get_owned_by()
func get_defending_actor() -> Actor:
	return contested_lander.get_units()[0].get_owned_by()


func get_invading_ready() -> bool:
	return invading_ready
func set_invading_ready(ready: bool):
	invading_ready = ready


func get_defending_ready() -> bool:
	return defending_ready
func set_defending_ready(ready: bool):
	defending_ready = ready


func get_dict() -> Dictionary:
	var dict = {
	"contested_lander" : contested_lander,
	"invading_lander" : invading_lander,
	"invading_units" : invading_units,
	"defending_units" : defending_units,
	"invading_ready" : invading_ready,
	"defending_ready" : defending_ready
	}

	return dict

### Connected Signals
