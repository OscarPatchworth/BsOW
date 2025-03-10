class_name Terrian extends Node3D 

@onready var dataStore = load("res://Scripts/main/data_store.gd")
@onready var terrianMesh = $baseHex
@onready var biomeMesh = $biomeHex

@onready var currentBiome = dataStore.biomeType.Plasma

#Terrian Has:
#Biome 
#Resources
#Weather overide BOOL
#POS Vector3
#ROT Vector3
#Building: Class
#Units: [Units]



# Called when the node enters the scene tree for the first time.
func _ready(currentBiome = dataStore.biomeType.Plasma) -> void:
	match currentBiome:
		dataStore.biomeType.Plasma:
			
			pass
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
