# match_settings.gd
class_name MatchSettings
extends Node

## Per-match rules. Lives in main.tscn as the "MatchSettings" node.

# Actors
@export var opponent_count: int = 1
@export var ai_starting_troops: int = 3
@export var starting_biome_count: int = 4

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


func get_ai_starting_troops() -> int:
	return AbilitySystem.resolve_get(self, &"ai_starting_troops", ai_starting_troops)


func get_starting_biome_count() -> int:
	return AbilitySystem.resolve_get(self, &"starting_biome_count", starting_biome_count)


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
