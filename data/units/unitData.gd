#UnitData.gd
class_name UnitData
extends Resource

enum UnitType {
	NULL = -1,
	MEELE_BASIC,
	MEELE_ADVNACED,
	RANGED_BASIC,
	RANGED_ADVANCED,
	SPECIAL
}

@export var base: UnitData
@export var name: String
@export var mesh: PackedScene
@export var icon: Texture2D
#@export var cost: EnconData
@export var type: UnitType = UnitType.NULL

###################################################################################################
## Get/set (er)s 

func get_unit_name() -> String:
	return name


func get_mesh() -> PackedScene:
	if(mesh != null):
		return mesh
	elif(base != null and base.get_mesh() != null):
		return base.get_mesh()
	else:
		print(str(name) + "is missing mesh and base mesh !!")
		return null


func get_icon() -> Texture2D:
	if(icon != null):
		return icon
	elif(base != null and base.get_icon() != null):
		return base.get_icon()
	else:
		print(str(name) + "is missing mesh and base icon !!")
		return null


func get_type() -> UnitType:
	if(type != UnitType.NULL):
		return type
	elif(base != null and base.get_type() != UnitType.NULL):
		return base.get_type()
	else:
		print(str(name) + "is missing mesh and base Type !!")
		return UnitType.NULL