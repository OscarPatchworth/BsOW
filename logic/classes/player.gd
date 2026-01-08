class_name Player
extends Actor


# signals
#signal score_changed

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables

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
	player_controller.selector_manager = selector_manager
	player_ui.selector_manager = selector_manager

### Connected Signals
func connect_signals():
	connect_player_signals()


func connect_player_signals():
	player_controller.view_lander_requested.connect(player_ui.display_landers_req)
	player_controller.select_lander.connect(selector_manager.select_lander_req)
