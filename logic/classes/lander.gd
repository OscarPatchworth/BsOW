class_name Lander
extends Node3D

signal built_action_completed(req: Action)
signal buy_unit_action_completed(req: Action)

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
const MAX_DEFUALT_UNITS: int = 5

# static variables

# @export variables
@export var biome_mesh: Node3D

# remaining regular variables
var has_building: bool = false
var has_units: bool = false
var biome_data: BiomeData
var building: BuildingObject
var units: Array[UnitObject] = []
var unit_capacity: int = MAX_DEFUALT_UNITS

# @onready variables
@onready var building_node: Node3D = self.find_child("Building")
@onready var units_node: Node3D = self.find_child("Units")

###################################################################################################
###	Methods
func free_children(target: Node):
	for child in target.get_children():
		child.queue_free()


func update_biome():
	biome_mesh.set_material(biome_data.mesh_material)


func update_unit_visuals():
	free_children(units_node)

	if(units.size() > 0):
		for i in range(units.size()):
			var unit_mesh = units[i].get_unit_data().get_mesh().instantiate()
			var angle = randf() * TAU
			var offset = Vector3(cos(angle), 0, sin(angle)) * 0.7
			unit_mesh.position += offset
			#unit_mesh.position.y = 0.5
			units_node.add_child(unit_mesh)
			#unit_mesh.look_at(self.global_position, self.building_node.global_position )
	elif(units_node.get_child_count() > 0 and units.size() < 1):
		free_children(units_node)


func add_units(new_units: Array[UnitObject]):
	for unit in new_units:
		if unit in units:
			print("Unit is alreay on lander")
			break
		else:
			units.append(unit)
			#print("Unit added to lander")
	update_unit_visuals()

func rmv_units(new_units: Array[UnitObject]):
	for unit in new_units:
		if unit not in units:
			print("Unit is alreay not on lander")
			break
		else:
			units.erase(unit)
			#print("Unit removed from lander")
	update_unit_visuals()


## Get/Set (er)s
func get_biome() -> BiomeData:
	return biome_data
func set_biome(new_biome: BiomeData):
	biome_data = new_biome
	update_biome()


func get_building_data() -> BuildingData:
	if(building == null) :
		print("Calling for NULL building on Lander!!")
		return null
	return building.get_building_data()


func get_units() -> Array[UnitObject]:
	return units

### Calls
func build_action(req: Action):
	var new_building = BuildingObject.new()
	new_building.set_building_data(req.get_building_type())
	new_building.bind_building_node(building_node)
	
	#building_node.add_child(new_building)
	building = new_building
	new_building.update_mesh()

	has_building = true
	built_action_completed.emit(req)


func buy_unit_action(req: Action):
	#print("Lander Recieved Request to buy unit")
	var new_unit = UnitObject.new()
	new_unit.setup(req.get_unit_type())
	new_unit.set_ownned_by(req.actor)	
	units.append(new_unit)
	self.has_units = true
	buy_unit_action_completed.emit(req)
	update_unit_visuals()
