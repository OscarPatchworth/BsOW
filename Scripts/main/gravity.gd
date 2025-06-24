extends Node
@onready var dataSettings = load("res://Scripts/main/settings_data.gd")
@onready var gravitySettings = $"../SettingsData".gravityType
@onready var center = $"../../World_Objects/Box"
var newBody: Node3D
var nbRb: RigidBody3D

@export var gravityImpulseTest = 15

const gConst = 6.6743E-11
var celestialBodies = [Terrian]

func _ready() -> void:
	if(gravitySettings == 0): # simple gravity):
		print("Simple Gravity")
	elif(gravitySettings == 1): #  continuous gravity
		print("continuous Gravity")
	print(center.name)
	pass
	

func getCelestialBodies() -> Array:
	celestialBodies = get_tree().get_nodes_in_group("terrian")
	return celestialBodies
	
func newTerrianAdded() -> void:
	if(getCelestialBodies()):
		newBody = celestialBodies[celestialBodies.size()-1]
		nbRb = newBody.get_child(0)
		print(newBody)
	else:
		pass
	var pullTarget = Vector3.ZERO
	var pullDirection = (pullTarget - nbRb.global_position).normalized()
	nbRb.apply_impulse(pullDirection * gravityImpulseTest )
	if(gravitySettings == 0): # simple gravity
		pass
	elif(gravitySettings == 1): #  continuous gravity
		pass
	

##	Applied Force Equation => a = G(m2/r^2) . vector


func _on_user_controler_biome_placed() -> void:
	newTerrianAdded()
	pass # Replace with function body.
