class_name Player
extends Actor


# signals
signal build_action_req(build_req: Action)
signal buy_unit_action_req(buy_unit_req: Action)

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var species: SpeciesData
var turn_manager: GameManager

# @export variables

# remaining regular variables

# @onready variables
@onready var player_controller: ActorControler = self.find_child("PlayerController")
@onready var player_ui: Control = self.find_child("UI-manager")
@onready var selector_manager:GameManager = self.find_child("SelectorManager")


###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_wires()
	connect_signals()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func connect_wires():
	wire_selector_manager()
	wire_turn_manager()


func wire_selector_manager():
	# Wire selector: manager->Things
	player_controller.selector_manager = selector_manager
	player_ui.bind_selector(selector_manager)
	# Wire selector: Things->Manager
	selector_manager.player = self


func wire_turn_manager():
	# Wire: manager -> Things
	player_ui.bind_turn_manager(turn_manager)


### Connected Signals
func connect_signals():
	connect_player_signals()
	connect_ui_signals()


func connect_player_signals():
	player_controller.view_lander_requested.connect(player_ui.display_landers_req)
	player_controller.select_lander.connect(selector_manager.select_lander_req)


func connect_ui_signals():
	player_ui.build_action_req.connect(self.fwd_build_req)
	player_ui.buy_unit_action_req.connect(self.fwd_buy_unit_action_req)


func fwd_build_req(build_req: Action):
	build_req.actor = self
	build_action_req.emit(build_req)


func fwd_buy_unit_action_req(buy_unit_req: Action):
	buy_unit_req.actor = self
	buy_unit_action_req.emit(buy_unit_req)


## Calls
func fwd_build_action_completed(req:Action):
	if req.actor == self:
		#print("Player recieved comfirmation of build action completed !!")
		player_ui.received_build_action_completed(req)
	else: pass


func fwd_buy_unit_action_completed(req: Action):
	if req.actor == self:
		#print("Player recieved comformation of unit purchase")
		player_ui.fwd_buy_unit_action_completed(req)
