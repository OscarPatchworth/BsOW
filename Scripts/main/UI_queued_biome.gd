extends Panel

@onready var active_queued_biome_UI = $ActiveBiome
@onready var queued_biome_UI = %QueuedBiome
@onready var data_store = $"../../../Env/DataStore"


func updated_biome_queue(activeQueuedBiome: Variant, queuedBiome: Variant) -> void:
	print(data_store.BiomeType.values().pick_random())
	match  activeQueuedBiome:
		data_store.BiomeType.BADLANDS:
			active_queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.BADLANDS_STYLEBOX))
		data_store.BiomeType.COAST:
			active_queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.COAST_STYLEBOX))
		data_store.BiomeType.FOREST:
			active_queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.FOREST_STYLEBOX))
		data_store.BiomeType.MOUNT:
			active_queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.MOUNT_STYLEBOX))
		data_store.BiomeType.OCEAN:
			active_queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.OCEAN_STYLEBOX))
		data_store.BiomeType.PLAINS:
			active_queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.PLAINS_STYLEBOX))
		data_store.BiomeType.PLASMA:
			active_queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.PLASMA_STLEBOX))
	
	####
	match  queuedBiome:
		data_store.BiomeType.BADLANDS:
			queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.BADLANDS_STYLEBOX))
		data_store.BiomeType.COAST:
			queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.COAST_STYLEBOX))
		data_store.BiomeType.FOREST:
			queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.FOREST_STYLEBOX))
		data_store.BiomeType.MOUNT:
			queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.MOUNT_STYLEBOX))
		data_store.BiomeType.OCEAN:
			queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.OCEAN_STYLEBOX))
		data_store.BiomeType.PLAINS:
			queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.PLAINS_STYLEBOX))
		data_store.BiomeType.PLASMA:
			queued_biome_UI.add_theme_stylebox_override("panel", load(data_store.PLASMA_STLEBOX))
	
	

	
