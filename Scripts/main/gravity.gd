extends Node
@onready var dataSettings = load("res://Scripts/main/settings_data.gd")
@onready var gravitySettings = $"../SettingsData".gravityType
@onready var center = $"../../World_Objects/Box"
var newBody: Node3D
var nbRb: RigidBody3D
var gravityPull = Vector3.ZERO

@export var gravityImpulseTest = 15

const gConst = 6.6743E-11
var celestialBodies = [Terrian]

func _ready() -> void:
	if(gravitySettings == 0): # simple gravity):
		print("Simple Gravity")
	elif(gravitySettings == 1): #  continuous gravity
		print("continuous Gravity")
	#print(center.name)
	pass

func _physics_process(delta: float) -> void:
	celestialBodies = get_tree().get_nodes_in_group("terrian")
	if celestialBodies.size() > 0:
		nbRb = celestialBodies[celestialBodies.size()-1].get_child(0)
		if !nbRb.is_sleeping():
			simpleG()

func getCelestialBodies() -> Array:
	celestialBodies = get_tree().get_nodes_in_group("terrian")
	return celestialBodies
	
func newTerrianAdded() -> void:
	if(getCelestialBodies()):
		newBody = celestialBodies[celestialBodies.size()-1]
		nbRb = newBody.get_child(0)
		#print(newBody)
	else:
		pass

	#var pullTarget = Vector3.ZERO
	#var pullDirection = (pullTarget - nbRb.global_position).normalized()
	#nbRb.apply_impulse(pullDirection * gravityImpulseTest )
	#nbRb.apply_impulse(gravityPull)
	
	if(gravitySettings == 0): # simple gravity
		pass
	elif(gravitySettings == 1): #  continuous gravity
		pass
	
func simpleG() -> void:
	for i in range(celestialBodies.size()-1):
		gravityPull = Vector3.ZERO
		var celestPos = celestialBodies[i].get_child(0).global_position
		var dist = sqrt((nbRb.global_position.x - celestPos.x)**2 + (nbRb.global_position.z - celestPos.z)**2 )
		var pullDir = (celestialBodies[i].get_child(0).global_position - nbRb.global_position).normalized()
		if dist < 0.6: dist = 0.6
		gravityPull = (pullDir * 300) / ((dist)**2)
		print(gravityPull)
		nbRb.add_constant_force(gravityPull)
##	Applied Force Equation => a = G(m2/r^2) . vector
func _on_user_controler_biome_placed() -> void:
	newTerrianAdded()
	pass # Replace with function body.
