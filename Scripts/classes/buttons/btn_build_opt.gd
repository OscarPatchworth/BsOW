extends Button

# signals
signal attempt_buy_build(build_res: BuildingRes)

# enums

# constants

# static variables
var build_res: BuildingRes
var game_master
var data_node_ref

# @export variables

# remaining regular variables

# @onready variables


###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


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
func connect_signals() -> void:
	self.attempt_buy_build


func _pressed() -> void:
	attempt_buy_build.emit(build_res)
