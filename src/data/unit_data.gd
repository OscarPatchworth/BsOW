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
@export var cost: EconData
@export var type: UnitType = UnitType.NULL
@export var dmg: DamageData
@export var can_build := false
@export var buildables: Array[BuildingData]

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


func get_dmg() -> DamageData:
	if dmg != null:
		return dmg
	elif(base != null and base.get_dmg() != null):
		return base.get_dmg()
	else:
		return null
		

func get_can_build() -> bool:
	return can_build
func set_can_build(yn: bool):
	can_build = yn


func get_buildables() -> Array[BuildingData]:
	if buildables != []:
		return buildables
	else:
		return base.get_buildables()
func add_buildable(b: BuildingData):
	if b not in buildables:
		buildables.append(b)
func rmv_buildable(b: BuildingData):
	if b in buildables:
		buildables.erase(b)


func get_cost() -> EconData:
	if cost != null: return cost
	else: return base.get_cost()


func get_base() -> UnitData:
	return base
func set_base(b: UnitData):
	self.base = b
