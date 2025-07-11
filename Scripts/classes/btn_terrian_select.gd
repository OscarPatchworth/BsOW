class_name BtnTerrianSelect # Class Name
extends Node

# signals

# enums

# constants

# static variables
var data_node_ref
var data_terrian

# @export variables

# remaining regular variables
var allocated_biome

# @onready variables

###################################################################################################
###	Methods

###	_built_in_methods()

# Called when the node enters the scene tree for the first time.\
func _init() -> void:
	data_node_ref = self.get_node("../%DataNodeRefs")
	data_terrian = get_node("../").get_node("/" + data_node_ref.DATA_TERRIAN)
	var rnd = randi_range(1, data_terrian.BiomeType.size()-1)
	allocated_biome = rnd
	print(allocated_biome)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### overridden built-in virtual methods:
func _pressed() -> void:
	print("Button Pressed \nTerrian Type: " + str(allocated_biome))
	data_terrian.set_active_biome(allocated_biome)

### Custom Methods


### Connected Signals
