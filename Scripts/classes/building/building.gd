class_name Building
extends Node

# signals

# enums

# constants

# static variables
var build_res: BuildingRes
var build_by: player
var controler: player
var terrain: Terrian

# @export variables

# remaining regular variables
var occupied = false
#var units = Array[Units]
#var has_health: bool
#var health: int

# @onready variables
@onready var data_node_ref = get_node("%DataNodeRefs")

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods


### Connected Signals
