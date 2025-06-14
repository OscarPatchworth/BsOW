extends Node
@onready var dataSettings = load("res://Scripts/main/settings_data.gd")
@onready var gravitySettings = $"../SettingsData".gravityType

const gConst = 6.6743E-11

var celestialBodies = [Terrian]

func getCelestialBodies() -> void:
	celestialBodies = get_tree().get_nodes_in_group("terrain")
	pass
	
func newBody(body) -> void:
	body.add_to_group("terrain")
	if(gravitySettings == 0): # simple gravity
		print("Simple Gravity")
	elif(gravitySettings == 1): #  continuous gravity
		print("continuous Gravity")
	pass


func _ready() -> void:
	if(gravitySettings == 0): # simple gravity):
		print("Simple Gravity")
	elif(gravitySettings == 1): #  continuous gravity
		print("continuous Gravity")
	pass



##	Applied Force Equation => a = G(m2/r^2) . vector
