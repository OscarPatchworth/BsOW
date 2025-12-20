class_name Terrian # Class Name
extends Node3D # Extends

# Signals
signal terrain_collision 

# Constants
const RAY_LENGTH = 1000

# static variables
var data_store
var gravity_node
var data_node_ref
var game_master
var biome: BiomeReS

# Export Vars
@export var sleeping_threshold_min = 0.05
@export var sleeping_threshold_max = 75
@export var update_time_interval = (1.0/15)
#@export var unit_capacity: int

# Dynamic Vars
var a3D_hits
var current_biome
var has_collided : bool
var building_res: BuildingRes
var built_on: bool
var building: Node3D
var unit_mesh_node: Node3D
var units: Array[Unit]
var connected_landers: Array[Terrian]

# OnReady Vars
@onready var biome_mesh = $RigidBody3D/biomeHex
@onready var rb = self.get_node("RigidBody3D")
@onready var a3D = rb.get_node("Area3D")
@onready var a3D_lander_detector = self.find_child("LanderDetector")
@onready var border_size = 100


#Terrian Has:
#Biome 
#Resources
#Weather overide BOOL
#POS Vector3
#ROT Vector3
#Building: Class
#Units: [Units]

###################################################################################################
###	_built_in_methods()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	# Enable collision detection
	a3D.set_monitoring(true)
	a3D.set_monitorable(true)	
	a3D_hits = 0
	a3D_lander_detector.set_monitoring(true)
	a3D_lander_detector.set_monitorable(true)

	# Enable rb freeze mode
	rb.set_freeze_mode(0)
	rb.set_freeze_enabled(false)

	# Setup Node Refs
	data_node_ref = self.get_node("../%DataNodeRefs")
	data_store = get_node("/" + data_node_ref.DATA_TERRIAN)
	game_master = get_node("/" + data_node_ref.GAME_MASTER)
	
	current_biome = data_store.BiomeType.PLASMA

	has_collided = false
	gravity_node = get_node("/" + data_node_ref.GRAVITY_NODE)
	gravity_node.reset_terrian_collision.connect(reset_collision)

	building = find_child("Building")
	unit_mesh_node = find_child("Unit_mesh")

	# Setup vars
	built_on = false

	# Test Funcs 


func _physics_process(delta):
	var rb_velocity = rb.get_linear_velocity()
	var rb_position = rb.get_global_position()

	#if moving
	if rb_velocity != Vector3.ZERO: 
		add_drag()
		#If rb is moving slowly, set it to sleep
		if(
				!rb.is_sleeping() 
				and rb_velocity.x < sleeping_threshold_min and rb_velocity.y < sleeping_threshold_min 
				and rb_velocity.z < sleeping_threshold_min
		):
			set_rb_sleep()
		#If rb is moving too fast, delete it
		elif(
				rb_velocity.x > sleeping_threshold_max or rb_velocity.y > sleeping_threshold_max 
				or rb_velocity.z > sleeping_threshold_max
			):
			delete_self()
		elif(
				rb_position.x > border_size or rb_position.x < -border_size or rb_position.z > border_size 
				or rb_position.z < -border_size
			):
			delete_self()
	else:
		rb.set_freeze_enabled(false)
	

###################################################################################################
### Custom Methods

func update_biome(newBiome: int) -> void:
	if(current_biome):
		current_biome = newBiome
		update_biome_material()
	else:
		pass


func update_biome_material() -> void:
	if(biome):
		biome_mesh.set_surface_override_material(0, biome.mesh_material)
	else:
		biome_mesh.set_surface_override_material(0, load(data_store.get_biome_res(current_biome)).mesh_material)


func set_biome(biome_ref: String) -> void:
	biome = load(biome_ref)
	update_biome_material()


func raycast_to_ground() -> bool:
	var space_state = get_world_3d().direct_space_state
	var ray_start = rb.global_position
	var ray_end = rb.global_position + (Vector3(0,-1,0) * 0.5)

	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	if result:
		return true
	else:
		return false


func add_drag() -> void:
	rb.set_angular_velocity(rb.get_angular_velocity() * 0.1)
	rb.set_linear_velocity(rb.get_linear_velocity() * 0.7)
	

func set_rb_sleep() -> void:
	if rb.is_sleeping():
		return
	rb.set_linear_velocity(Vector3.ZERO)
	rb.set_sleeping(true)


func delete_self() -> void:
	self.remove_from_group("terrian")
	self.queue_free()


func ready_building() -> void:
	if(randi_range(0,1)):
		if(randi_range(0,1)):
			add_building(data_node_ref.BUILDING_HQ)
		else:
			add_building(data_node_ref.BUILDING_TOWER)
	else:
		built_on = false


func add_building(building_ref) -> void:
	if(typeof(building_ref) == TYPE_STRING):
		building_res = load(building_ref)
	elif(building_ref is BuildingRes):
		building_res = building_ref
	else:
		print("Terrian.add_building(building_ref) invalid input type \n")
		
	if(built_on == false):
		var build_mesh = building_res.build_mesh.instantiate()
		build_mesh.set_script(load(data_node_ref.CLASS_BUILDING))
		build_mesh.add_to_group("buildings")
		
		build_mesh.build_res = building_res
		var active_player = game_master.get_active_player()
		build_mesh.build_by = active_player
		build_mesh.controler = active_player
		build_mesh.terrain = self

		building.add_child(build_mesh)
		build_mesh.position.y = 0.6

		built_on = true
	else:
		print("Already built on!!")


func add_unit(unit_ref) -> void:
	# Assign Correct ref type
	var unit_res: UnitRes
	if(typeof(unit_ref) == TYPE_STRING):
		unit_res = load(unit_ref)
	elif(unit_ref is UnitRes):
		unit_res = unit_ref
	else:
		print("Unit.add_unit(unit_ref) invalid input type \n")

	# Instance Unit
	var unit = Unit.new() 
	unit.set_script(load(data_node_ref.CLASS_UNIT))
	unit.setup(unit_res)
	unit.owner = game_master.get_active_player()
	#unit.add_to_group("units")
	units.append(unit)

	update_mesh_units()


func add_ext_unit(unit: Unit):
	units.append(unit)
	update_mesh_units()


func rvm_unit(unit):
	if unit in units:
		units.erase(unit)
	update_mesh_units()

func update_mesh_units():
	free_children(unit_mesh_node)

	if(units.size() > 0):
		for i in range(units.size()):
			var unit_mesh = units[0].unit_res.mesh.instantiate()
			unit_mesh.position.y = 0.5
			var angle = randf() * TAU
			var offset = Vector3(cos(angle), 0, sin(angle)) * 0.7
			unit_mesh.position += offset
			unit_mesh.look_at(self.global_position, Vector3.UP)
			unit_mesh_node.add_child(unit_mesh)
	elif(unit_mesh_node.get_child_count() > 0 and units.size() < 1):
		free_children(unit_mesh_node)


func rmv_building() -> void:
	if(built_on):
		building_res = null
		built_on = false

		var building_instance = building.get_child(0)
		building_instance.queue_free()


func get_connected_landers() -> Array[Terrian]:
	connected_landers = []
	for i in a3D_lander_detector.get_overlapping_bodies():
		if((i.get_parent() in connected_landers) == false and i.get_parent() != self):
			connected_landers.append(i.get_parent()) 
		
	return connected_landers

func free_children(target: Node):
	for child in target.get_children():
		child.queue_free()

###################################################################################################
###################################################################################################
###	Connected Signals

func _on_area_3d_body_entered(body: Node3D) -> void:
	if(body != self.get_node("RigidBody3D")): # Ignore self collision
		a3D_hits += 1
		has_collided = true
		terrain_collision.emit()
	if a3D_hits > 0:
		pass


func _on_area_3d_body_exited(body: Node3D) -> void:
	a3D_hits -= 1
	# If there are no more hits, unfreeze the rigid body
	if a3D_hits <= 0:
		#rb.set_freeze_enabled(false)
		pass


func reset_collision() -> void:
	has_collided = false
	rb.set_sleeping(false)
