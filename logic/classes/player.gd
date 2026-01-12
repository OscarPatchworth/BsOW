class_name Player
extends Actor


# signals
signal build_action_req(build_req)

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var species: SpeciesData
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


func wire_selector_manager():
	# Wire selector: manager->Things
	player_controller.selector_manager = selector_manager
	player_ui.bind_selector(selector_manager)
	# Wire selector: Things->Manager
	selector_manager.player = self


### Connected Signals
func connect_signals():
	connect_player_signals()
	connect_ui_signals()


func connect_player_signals():
	player_controller.view_lander_requested.connect(player_ui.display_landers_req)
	player_controller.select_lander.connect(selector_manager.select_lander_req)


func connect_ui_signals():
	player_ui.build_action_req.connect(self.fwd_build_req)


func fwd_build_req(build_req: Action):
	build_req.actor = self
	build_action_req.emit(build_req)
