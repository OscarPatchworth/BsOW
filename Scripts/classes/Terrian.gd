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
func _ready() -> void:
	updateBiome(dataStore.biomeType.values().pick_random())
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


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
