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

# Export Vars
@export var sleeping_threshold_min = 0.05
@export var sleeping_threshold_max = 75
@export var update_time_interval = (1.0/15)

# Dynamic Vars
var a3D_hits
var current_biome
var has_collided : bool
#var buildings: Building
var built_on: bool

# OnReady Vars
@onready var biome_mesh = $RigidBody3D/biomeHex
@onready var rb = self.get_node("RigidBody3D")
@onready var a3D = rb.get_node("Area3D")
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

	# Enable rb freeze mode
	rb.set_freeze_mode(0)
	rb.set_freeze_enabled(false)

	# Setup Node Refs
	data_node_ref = self.get_node("../%DataNodeRefs")
	data_store = get_node("/" + data_node_ref.DATA_TERRIAN)
	
	current_biome = data_store.BiomeType.PLASMA

	has_collided = false
	gravity_node = get_node("/" + data_node_ref.GRAVITY_NODE)
	gravity_node.reset_terrian_collision.connect(reset_collision)

	# Setup vars
	built_on = true

	# Test Funcs 
	ready_building()


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
	biome_mesh.set_surface_override_material(0, load(data_store.get_biome_material(current_biome)))


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
			var build = data_store.building_HQ.instantiate()
			var building_node = find_child("Building")
			building_node.add_child(build)
			build.position.y = 0.6
		else:
			var build = data_store.building_Tower.instantiate()
			var building_node = find_child("Building")
			building_node.add_child(build)
			build.position.y = 0.6

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
