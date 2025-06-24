extends Node
@onready var dataSettings = load("res://Scripts/main/settings_data.gd")
@onready var gravitySettings = $"../SettingsData".gravityType
@onready var center = $"../../World_Objects/Box"
var new_body: Node3D

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
	
func newBody(body) -> void:
	if(gravitySettings == 0): # simple gravity
		print("Simple Gravity")
	elif(gravitySettings == 1): #  continuous gravity
		print("continuous Gravity")
	#print("Number of nodes in Terrian Group: " + str(get_tree().get_node_count_in_group("terrian")))
	if(getCelestialBodies()):
		new_body = celestialBodies[celestialBodies.size()-1]
		#new_body.rb.linear_velocity = (Vector3(1,0,0)) * 10000

##	Applied Force Equation => a = G(m2/r^2) . vector
