extends Button

# signals
signal attempt_buy_unit(build_res: BuildingRes, callback)
signal build_on_terrian(build_res:BuildingRes)
# enums

# constants

# static variables
var unit_res: UnitRes
var game_master
var data_node_ref

# @export variables

# remaining regular variables
var can_pay_build = false
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
func set_unit_data(unit_data: UnitRes) -> void:
	unit_res = unit_data
	update_btn_data()


func update_btn_data() -> void:
	if(unit_res):
		icon = unit_res.icon
	else:
		pass


### Connected Signals
func connect_signals() -> void:
	self.attempt_buy_build


func _pressed() -> void:
	# chatGPT showed me callbacks ... way more confuzing than I remember
	var callback = func(can_pay): can_pay_build = can_pay
	attempt_buy_unit.emit(unit_res, callback)
	#if(can_pay_build):
		#build_on_terrian.emit(unit_res)
