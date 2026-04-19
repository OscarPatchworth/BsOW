#match_settings.gd
extends Node

# Actor Settings
@export var number_of_opponents: int = 1
@export var starting_simple_troops: int = 3
@export var starting_biomes_amount: int = 4

# Lander Settings
@export var game_biomes: Array[BiomeData]

# Map Settings
@export var map_size: int = 10

# Combat Units
var max_attack_units: int = 3
var max_defend_units: int = 3

var max_attack_ablt: int = 10
var max_defend_ablt: int = 10

# Resource Settings


# Season Settings





###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals


## Calls

## Get/Set (er)s

### Connected Signals
