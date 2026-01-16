#building_object.gd
class_name BuildingObject
extends Node

# signals

# enums

# constants

# static variables
var building_data: BuildingData
var build_node: Node3D
# @export variables

# remaining regular variables
var hit_points: int = 1

# @onready variables

###################################################################################################
###	Methods
func free_children(target: Node):
	for child in target.get_children():
		child.queue_free()

### Connected Signals


## Calls
func setup(building_type: BuildingData):
	building_data = building_type


func update_mesh():
	free_children(build_node)
	var build_mesh = building_data.get_mesh().instantiate()
	build_node.add_child(build_mesh)


func bind_building_node(build_node: Node3D):
	self.build_node = build_node

## Get/Set (er)s
func get_building_data() -> BuildingData:
	return building_data
func set_building_data(build: BuildingData):
	self.building_data = build


### Connected Signals