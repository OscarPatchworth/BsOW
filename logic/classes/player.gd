class_name Player
extends Actor


# signals
signal build_action_req(build_req: Action)
signal buy_unit_action_req(buy_unit_req: Action)
signal move_units_action_req(move_units_req: Action)
signal attack_action_req(req: Action)

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
	wire_turn_manager()
	wire_lander_manager()
	wire_combat_manager()
	wire_self()


func wire_selector_manager():
	# Wire selector: manager->Things
	player_controller.selector_manager = selector_manager
	player_ui.bind_selector(selector_manager)
	# Wire selector: Things->Manager
	selector_manager.player = self


func wire_turn_manager():
	# Wire: manager -> Things
	player_ui.bind_turn_manager(turn_manager)


func wire_lander_manager():
	# Wire: manager -> Things
	player_ui.bind_lander_manager(lander_manager)


func wire_combat_manager():
	# Wire: manager -> Things
	player_ui.bind_combat_manager(combat_manager)


func wire_self():
	player_ui.bind_player(self)

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
	player_ui.move_units_action_req.connect(self.fwd_move_units_req)
	player_ui.attack_action_req.connect(self.fwd_attack_action_req)


func fwd_build_req(build_req: Action):
	build_req.actor = self
	build_action_req.emit(build_req)


func fwd_buy_unit_action_req(buy_unit_req: Action):
	buy_unit_req.actor = self
	buy_unit_action_req.emit(buy_unit_req)


func fwd_move_units_req(move_units_req: Action):
	move_units_req.actor = self
	move_units_action_req.emit(move_units_req)



func fwd_attack_action_req(req: Action):
	req.actor = self
	attack_action_req.emit(req)

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


func fwd_move_units_action_completed(req: Action):
	if(req.actor == self or 
	selector_manager.get_selected_lander() == req.get_selected_lander() or 
	req.get_target_lander() == selector_manager.get_target_lander()):
		player_ui.fwd_move_units_action_completed(req)


func contest_lander(contest: Contest):
	#print("Player | Contest Lander call recieved")

	# Check if this combat involves this player
	if(contest.get_invading_actor() == self or contest.get_defending_actor() == self):
		print("Player | Entering lander contest")
		player_ui.run_combat_display(contest)
	else:
		# Player is not involved in combat
		# Do not need to do anything
		# May want to put player in spectator mode or smth later
		pass


func combat_req(contest: Contest):
	print("Player | Combat Req recieved")
	# We are assuming: contest.get_contested_lander().get_units() != null 
	if(contest.get_invading_actor() == self or contest.get_defending_actor() == self):
		var cmb_pos = "Attacker" if contest.get_invading_actor() == self else "Defender"
		print("Player | Entering Combat as: " + cmb_pos)
		player_ui.run_combat_display(contest)
