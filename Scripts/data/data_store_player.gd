extends Node

# signals

# enums

# constants
const RACE_APE_REF = "res://Scripts/classes/race/ape.tres"

# static variables
var race_ref = {
	"Ape": RACE_APE_REF
}


# @export variables

# remaining regular variables

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
func rnd_race() -> String:
	return race_ref.values()[randi() % race_ref.size()]

### Connected Signals