# species_data.gd
class_name SpeciesData
extends Resource

## Authored definition of a playable species.

@export var display_name: String
## A line or two about the race (shown on the race select screen).
@export_multiline var description: String
@export var buildings: Array[BuildingData] = []
@export var units: Array[UnitData] = []
@export var starting_biomes: Array[BiomeData] = []
@export var command_tower: BuildingData
## Race traits (apply to this race's units). See Ability.
@export var abilities: Array[Ability] = []


#region Accessors
func get_display_name() -> String:
	return AbilitySystem.resolve_get(self, &"display_name", display_name)


func get_description() -> String:
	return AbilitySystem.resolve_get(self, &"description", description)


func get_buildings() -> Array[BuildingData]:
	return AbilitySystem.resolve_get(self, &"buildings", buildings)


func get_units() -> Array[UnitData]:
	return AbilitySystem.resolve_get(self, &"units", units)


func get_starting_biomes() -> Array[BiomeData]:
	return AbilitySystem.resolve_get(self, &"starting_biomes", starting_biomes)


func get_command_tower() -> BuildingData:
	return AbilitySystem.resolve_get(self, &"command_tower", command_tower)


## Abilities this brings into play (see Ability).
func get_abilities() -> Array[Ability]:
	return AbilitySystem.resolve_get(self, &"abilities", abilities)
#endregion
