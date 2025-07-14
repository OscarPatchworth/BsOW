extends Node

###		Settings Option Enums	###
###################################################################################################
###################################################################################################
enum GravityForceTypes {IMPULSE, CONSTANT, CONTINUOUS}
enum GravityAffectedTerrian {NEW, ALL}


###		Settings Option Consts	###
###################################################################################################
###################################################################################################
const starting_terrian_amount: int = 4


###		Settings Var values		###
###################################################################################################
###################################################################################################
var gravity_type = GravityForceTypes.CONTINUOUS
var gravity_affected = GravityAffectedTerrian.ALL


func _on_gravity_ready() -> void:
	pass # Replace with function body.
