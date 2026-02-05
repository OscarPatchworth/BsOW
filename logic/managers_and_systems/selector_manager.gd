#selector_manager.gd
extends GameManager

# signals
signal selected_units_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var player: Player

# @export variables

# remaining regular variables
var selected_lander:Lander
var selected_units: Array[UnitObject]

# @onready variables

###################################################################################################
###	Get/Set (er)s
func get_selected_lander() -> Lander:
	return selected_lander
func set_selected_lander(lander: Lander):
	selected_lander = lander


func get_player() -> Player:
	return player


func get_selected_units() -> Array[UnitObject]:
	return selected_units


func add_unit_selected_units(unit: UnitObject):
	if unit in selected_units:
		print("""
		Selector Manager Err:
			added unit already exisits in selected_units[]
		""")
		return
	selected_units.append(unit)
	selected_units_changed.emit()
	print("Unit Added")


func rmv_unit_selected_units(unit: UnitObject):
	if unit not in selected_units:
		print(""" 
		Selector Manager Err:
			unit does not exisit in selected_units[]
		""")
		return
	selected_units.erase(unit)
	selected_units_changed.emit()
	print("unit rmv")


func clear_selected_units():
	selected_units = []

	
### Connected Signals and Signals
func select_lander_req(lander: Lander):
	set_selected_lander(lander)


