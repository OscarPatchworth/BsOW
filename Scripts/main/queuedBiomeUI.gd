extends Panel

@onready var activeQueuedBiomeUI = $ActiveBiome
@onready var queuedBiomeUI = %QueuedBiome
@onready var dataStore = $"../../../Env/DataStore"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func updated_biome_queue(activeQueuedBiome: Variant, queuedBiome: Variant) -> void:
	match  activeQueuedBiome:
		dataStore.biomeType.Badlands:
			activeQueuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.BADLANDS_STYLEBOX))
		dataStore.biomeType.Coast:
			activeQueuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.COAST_STYLEBOX))
		dataStore.biomeType.Forest:
			activeQueuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.FOREST_STYLEBOX))
		dataStore.biomeType.Mount:
			activeQueuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.MOUNT_STYLEBOX))
		dataStore.biomeType.Ocean:
			activeQueuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.OCEAN_STYLEBOX))
		dataStore.biomeType.Plains:
			activeQueuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.PLAINS_STYLEBOX))
		dataStore.biomeType.Plasma:
			activeQueuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.PLASMA_STLEBOX))
	
	####
	match  queuedBiome:
		dataStore.biomeType.Badlands:
			queuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.BADLANDS_STYLEBOX))
		dataStore.biomeType.Coast:
			queuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.COAST_STYLEBOX))
		dataStore.biomeType.Forest:
			queuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.FOREST_STYLEBOX))
		dataStore.biomeType.Mount:
			queuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.MOUNT_STYLEBOX))
		dataStore.biomeType.Ocean:
			queuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.OCEAN_STYLEBOX))
		dataStore.biomeType.Plains:
			queuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.PLAINS_STYLEBOX))
		dataStore.biomeType.Plasma:
			queuedBiomeUI.add_theme_stylebox_override("panel", load(dataStore.PLASMA_STLEBOX))
	
	

	
