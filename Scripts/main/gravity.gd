# Class Name
extends Node # Extends

# Constants
const GRAVITY_CONST = 6.6743E-11

# Static Vars
var calc_gravity = false
var num_Celestial_bodies = 0
var active_celestial_collider

# Export Vars
@export var gravity_impulse_test = 15

# Dynamic Vars
var new_body: Node3D
var new_body_rb: RigidBody3D
var gravity_pull = Vector3.ZERO
var celestial_bodies = [Terrian]

# OnReady Vars
@onready var data_settings = load("res://Scripts/main/settings_data.gd")
@onready var gravity_settings = $"../SettingsData".gravity_type
@onready var center = $"../../World_Objects/Box"


func _ready() -> void:
	if(gravity_settings == 0): # simple gravity):
		print("Simple Gravity")
	elif(gravity_settings == 1): # continuous gravity
		print("continuous Gravity")
	pass


func _process(delta: float) -> void:
	if num_Celestial_bodies < get_tree().get_nodes_in_group("terrian").size():
		celestial_bodies = get_tree().get_nodes_in_group("terrian")
		num_Celestial_bodies = celestial_bodies.size()

		newTerrianAdded()
		print("New Terrian Added")

		celestial_bodies = get_tree().get_nodes_in_group("terrian")
		new_body_rb = celestial_bodies[celestial_bodies.size()-1].get_node("RigidBody3D")

	else:
		pass


func _physics_process(delta: float) -> void:
	if(calc_gravity and new_body_rb != null):
		if !new_body_rb.is_sleeping():
			simpleG()


func getcelestial_bodies() -> Array:
	celestial_bodies = get_tree().get_nodes_in_group("terrian")
	return celestial_bodies
	

func newTerrianAdded() -> void:
	if(getcelestial_bodies()):
		new_body = celestial_bodies[celestial_bodies.size()-1]
		new_body_rb = new_body.get_node("RigidBody3D")
		calc_gravity = true
		new_body.terrain_collision.connect(stop_calc_gravity)
	else:
		pass


##	Applied Force Equation => a = G(m2/r^2) . vector
func _on_user_controler_biome_placed() -> void:
	if(gravity_settings == 0): # simple gravity
		pass
	elif(gravity_settings == 1): #  continuous gravity
		pass
	

func simpleG() -> void:
	# Calc & apply g-force from each Celest_body onto new_terrian
	for i in range(celestial_bodies.size()-1):
		gravity_pull = Vector3.ZERO #var pullTarget = Vector3.ZERO

		#var pullDirection = (pullTarget - new_body_rb.global_position).normalized()
		var pullDir = (celestial_bodies[i].get_node("RigidBody3D").global_position - new_body_rb.global_position).normalized()
		pullDir.y = 0

		# Dist(m1, m2)
		var celestPos = celestial_bodies[i].get_node("RigidBody3D").global_position
		var dist = sqrt((new_body_rb.global_position.x - celestPos.x)**2 + (new_body_rb.global_position.z - celestPos.z)**2 )
		if dist < 0.6: dist = 0.6

		# f(m1) = (m2 / dist^2) . pullDir
		gravity_pull = (7000 / (dist**2)) * pullDir
		new_body_rb.apply_force(gravity_pull)


func stop_calc_gravity() -> void:
	calc_gravity = false
	print("Gravity Calculation Stopped")
