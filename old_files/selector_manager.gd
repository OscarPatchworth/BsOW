#selector_manager.gd
extends Node

# signals
signal origin_units_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var self_player: Player

# @export variables

# remaining regular variables
var origin_lander:Lander
var origin_units: Array[UnitObject]
var target_lander: Lander

# @onready variables

###################################################################################################
###	Get/Set (er)s
func get_origin_lander() -> Lander:
	return origin_lander
func set_origin_lander(lander: Lander):
	origin_lander = lander
	


func get_target_lander() -> Lander:
	return target_lander
func set_target_lander(lander: Lander):
	target_lander = lander


func get_player() -> Player:
	return self_player


func get_origin_units() -> Array[UnitObject]:
	return origin_units


func add_unit_origin_units(unit: UnitObject):
	if unit in origin_units:
		print("""
		Selector Manager Err:
			added unit already exisits in origin_units[]
		""")
		return
	origin_units.append(unit)
	origin_units_changed.emit()
	print("Unit Added")


func rmv_unit_origin_units(unit: UnitObject):
	if unit not in origin_units:
		print(""" 
		Selector Manager Err:
			unit does not exisit in origin_units[]
		""")
		return
	origin_units.erase(unit)
	origin_units_changed.emit()
	print("unit rmv")


func clear_origin_units():
	origin_units = []


### Connected Signals and Signals
func select_lander_req(lander: Lander):
	set_origin_lander(lander)
