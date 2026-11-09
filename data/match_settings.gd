# match_settings.gd
class_name MatchSettings
extends Node

## Per-match rules. Lives in main.tscn as the "MatchSettings" node.

# Actors
@export var opponent_count: int = 1
@export var starting_biome_count: int = 4

# Economy
## Every resource in a new actor's wallet starts at this amount.
@export var starting_resource_amount: int = 10
## Gold every actor gains at the start of their turn (UPKEEP), on top of their landers' upkeep.
@export var upkeep_gold: int = 3

# Pacing
## Seconds between the AI's actions on its turn (0 = instant).
@export var ai_step_delay: float = 0.6

# Landers
@export var game_biomes: Array[BiomeData] = []

# Map
@export var map_size: int = 10

# Combat
@export var max_attacker_units: int = 3
@export var max_defender_units: int = 3
@export var max_attacker_abilities: int = 10
@export var max_defender_abilities: int = 10


#region Accessors
func get_opponent_count() -> int:
	return AbilitySystem.resolve_get(self, &"opponent_count", opponent_count)


## The biomes an actor of `species` places during setup: the species' starting biomes (if
## allowed in this match), topped up with random game biomes. Same rule for every actor.
func pick_starting_biomes(species: SpeciesData) -> Array[BiomeData]:
	var picked: Array[BiomeData] = []
	var species_biomes := species.get_starting_biomes()
	var biomes := get_game_biomes()
	for i in get_starting_biome_count():
		if i < species_biomes.size() and species_biomes[i] in biomes:
			picked.append(species_biomes[i])
		else:
			picked.append(biomes.pick_random())
	return picked


func get_starting_biome_count() -> int:
	return AbilitySystem.resolve_get(self, &"starting_biome_count", starting_biome_count)


func get_starting_resource_amount() -> int:
	return AbilitySystem.resolve_get(self, &"starting_resource_amount", starting_resource_amount)


func get_upkeep_gold() -> int:
	return AbilitySystem.resolve_get(self, &"upkeep_gold", upkeep_gold)


func get_ai_step_delay() -> float:
	return ai_step_delay


func get_game_biomes() -> Array[BiomeData]:
	return AbilitySystem.resolve_get(self, &"game_biomes", game_biomes)


func get_map_size() -> int:
	return AbilitySystem.resolve_get(self, &"map_size", map_size)


func get_max_attacker_units() -> int:
	return AbilitySystem.resolve_get(self, &"max_attacker_units", max_attacker_units)


func get_max_defender_units() -> int:
	return AbilitySystem.resolve_get(self, &"max_defender_units", max_defender_units)


func get_max_attacker_abilities() -> int:
	return AbilitySystem.resolve_get(self, &"max_attacker_abilities", max_attacker_abilities)


func get_max_defender_abilities() -> int:
	return AbilitySystem.resolve_get(self, &"max_defender_abilities", max_defender_abilities)
#endregion
