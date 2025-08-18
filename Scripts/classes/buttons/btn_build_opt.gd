extends Button

# signals

# enums

# constants

# static variables
var build_res: BuildingRes

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
func set_build_data(build: BuildingRes) -> void:
	build_res = build
	update_btn_data()

func update_btn_data() -> void:
	if(build_res):
		icon = build_res.build_icon


### Connected Signals