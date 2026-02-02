extends Control

# signals
signal build_action_req(build_req)
signal buy_unit_action_req(buy_unit_req)

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants

# static variables
var turn_manager: GameManager

# @export variables

# remaining regular variables
var selector_manager:GameManager
var lander_manager: GameManager

# @onready variables
@onready var lander_panel:Panel = self.find_child("LanderPanel")
@onready var biome_label: Label = lander_panel.find_child("BiomeLabel")
@onready var building_control:Control = self.find_child("BuildingControl")
@onready var unit_control: Control = self.find_child("UnitControl")
@onready var lander_control: Control = self.find_child("LanderControl")
@onready var turn_panel: Panel = self.find_child("TurnPanel")

###################################################################################################
###	Methods
func _ready() -> void:
	connect_signals()
	connect_wires()

	lander_panel.hide()
		

### Signals and wires
func connect_signals():
	lander_panel.build_action_req.connect(self.fwd_build_request)
	lander_panel.buy_unit_action_req.connect(self.fwd_buy_unit_action_req)


func connect_wires():
	wire_selector_manager()


func wire_selector_manager():
	pass

### Connected Signals
func bind_selector(selector: GameManager):
	selector_manager = selector
	#print("UI manager selector bound")
	
	lander_panel.bind_selector(selector)


func bind_turn_manager(tm: GameManager):
	# Bind self
	turn_manager = tm
	# Bind Children
	turn_panel.bind_turn_manager(tm)


func bind_lander_manager(lm: GameManager):
	lander_manager = lm
	lander_panel.bind_lander_manager(lm)

func display_landers_req(lander: Lander):
	lander_panel.show()
	lander_panel.update()


func fwd_build_request(build_req: Action):
	build_action_req.emit(build_req)


func fwd_buy_unit_action_req(buy_unit_req: Action):
	buy_unit_action_req.emit(buy_unit_req)


## Calls
func received_build_action_completed(req: Action):
	lander_panel.update()


func fwd_buy_unit_action_completed(req: Action):
	lander_panel.update()
