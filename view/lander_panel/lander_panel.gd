#lander_panel.gd

extends Panel

# signals
signal build_action_req(req: Action)

# enums

# constants

# static variables

# remaining regular variables
var selector_manager:GameManager

# @onready variables
@onready var building_control: Control = self.find_child("BuildingControl")
@onready var unit_control: Control = self.find_child("UnitControl")
@onready var biome_label: Label = find_child("BiomeLabel")

###################################################################################################
###	Methods
func _ready() -> void:
	connect_signals()
	connect_wires()

### Connected Signals
func bind_selector(selector):
	selector_manager = selector
	#print("Lander Panel selector Manager bound")

	building_control.bind_selector(selector)
	unit_control.bind_selector(selector)


func update_building_control(cur_lander: Lander):
	if cur_lander.has_building:
		building_control.set_state_building_details()
	else:
		building_control.set_state_building_shop()


func update_unit_control(cur_lander: Lander):
	if cur_lander.has_units:
		unit_control.set_state_details()
	else:
		unit_control.set_state_shop()

## Calls

func update():
	var cur_lander = selector_manager.get_selected_lander()
	biome_label.text = str(cur_lander.biome_data.name)

	update_building_control(cur_lander)
	update_unit_control(cur_lander)	


### Connected Signals
func connect_signals():
	building_control.build_action_req.connect(self.fwd_build_request)


func connect_wires():
	pass


func fwd_build_request(req):
	build_action_req.emit(req)
