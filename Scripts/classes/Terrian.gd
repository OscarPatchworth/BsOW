class_name Terrian extends Node3D 

@export var sleepingThresholdMin = 0.15
@export var sleepingThresholdMax = 75
@export var updateTimeInterval = 1/4 * 1000

@onready var dataStore = load("res://Scripts/main/data_store.gd")
#@onready var terrianMesh = $RigidBody3D/baseHex
@onready var biomeMesh = $RigidBody3D/biomeHex
@onready var rb = self.get_node("RigidBody3D")#rigidbody
@onready var currentBiome = dataStore.biomeType.Plasma
@onready var force: Vector3 = Vector3(2, 0, (0))

@onready var updateTimer = 0

#Terrian Has:
#Biome 
#Resources
#Weather overide BOOL
#POS Vector3
#ROT Vector3
#Building: Class
#Units: [Units]



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	updateBiome(dataStore.biomeType.values().pick_random())
	rb.set_contact_monitor(true)
	
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#rb.add_constant_torque(force)
	pass

const RAY_LENGTH = 1000

func _physics_process(delta):
	updateTimer =+ delta
	
	if(updateTimer > updateTimeInterval):
		var velocity = rb.get_linear_velocity()
		if(velocity.x < sleepingThresholdMin and velocity.y < sleepingThresholdMin and velocity.z < sleepingThresholdMin and raycastToGroud()):
			rb.set_sleeping(true)
		if(velocity.x > sleepingThresholdMax or velocity.y > sleepingThresholdMax or velocity.z > sleepingThresholdMax):
			self.remove_from_group("terrian")
			self.queue_free()
		updateTimer = 0

func updateBiome(newBiome: int) -> void:
	currentBiome = newBiome
	updateBiomeMaterial()

func updateBiomeMaterial() -> void:
	match currentBiome:
		dataStore.biomeType.Plasma:
			biomeMesh.set_surface_override_material(0, load(dataStore.PLASMA_MATERIAL))
		dataStore.biomeType.Badlands:
			biomeMesh.set_surface_override_material(0, load(dataStore.BADLANDS_MATERIAL))
		dataStore.biomeType.Coast:
			biomeMesh.set_surface_override_material(0, load(dataStore.COAST_MATERIAL))
		dataStore.biomeType.Forest:	
			biomeMesh.set_surface_override_material(0, load(dataStore.FOREST_MATERIAL))
		dataStore.biomeType.Mount:
			biomeMesh.set_surface_override_material(0, load(dataStore.MOUNT_MATERIAL))
		dataStore.biomeType.Ocean:
			biomeMesh.set_surface_override_material(0, load(dataStore.OCEAN_MATERIAL))
		dataStore.biomeType.Plains:
			biomeMesh.set_surface_override_material(0, load(dataStore.PLAINS_MATERIAL))

func raycastToGroud() -> bool:
	var space_state = get_world_3d().direct_space_state
	var rayStart = rb.global_position
	var rayEnd = rb.global_position + (Vector3(0,-1,0) * 0.5)

	var query = PhysicsRayQueryParameters3D.create(rayStart, rayEnd)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	
	if result:
		return true
	else:
		return false
