class_name Player
extends Actor


# signals
signal build_action_req(build_req: Action)
signal buy_unit_action_req(buy_unit_req: Action)
signal move_units_action_req(move_units_req: Action)
signal attack_action_req(req: Action)

signal combat_unit_selected(who: Actor, thing: UnitObject, select:bool)
signal unit_deslected(who: Actor, thing: UnitObject, select:bool)

signal player_combat_ready(who: Actor, thing: Variant, select: bool)
signal player_combat_not_ready(who: Actor, thing: Variant, select: bool)

signal next_phase_req(req: Action)

signal purchase_action_req(req: Action)

signal close_market()

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants
#const MAX_SPEED = 200

# static variables
var draw_3d: Draw3D

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
	wire_wallet()
	wire_draw_3d()


func wire_selector_manager():
	# Wire selector: manager->Things
	player_controller.selector_manager = selector_manager
	player_ui.bind_selector(selector_manager)
	# Wire selector: Things->Manager
	selector_manager.self_player = self


func wire_turn_manager():
	# Wire: manager -> Things
	player_ui.bind_turn_manager(turn_manager)
	player_controller.bind_turn_manager(turn_manager)


func wire_lander_manager():
	# Wire: manager -> Things
	player_ui.bind_lander_manager(lander_manager)
	player_controller.bind_lander_manager(lander_manager)


func wire_combat_manager():
	# Wire: manager -> Things
	player_ui.bind_combat_manager(combat_manager)


func wire_self():
	player_ui.bind_player(self)
	player_controller.bind_player(self)


func wire_wallet():
	player_ui.bind_wallet(wallet)


func wire_draw_3d():
	player_controller.draw_3d = draw_3d

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
	player_ui.unit_selected.connect(self.fwd_combat_unit_selected)
	player_ui.unit_deslected.connect(self.fwd_unit_deslected)
	player_ui.player_combat_ready.connect(self.fwd_player_combat_ready)
	player_ui.player_combat_not_ready.connect(self.fwd_player_combat_not_ready)
	player_ui.next_phase_req.connect(self.fwd_next_phase_req)
	player_ui.move_action_req.connect(self.fwd_move_action_req)
	player_ui.purchase_action_req.connect(self.fwd_purchase_action_req)
	wallet.econ_changed.connect(player_ui.econ_changed)


	player_controller.attack_action_req.connect(self.fwd_attack_action_req)
	player_controller.run_movement_ui.connect(player_ui.run_movement)

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


func fwd_unit_deslected(unit: UnitObject):
	# who: Actor, thing: UnitObject, select:bool
	unit_deslected.emit(self, unit, false)


func fwd_player_combat_ready():
	# who: Actor, thing: Variant, select: bool
	player_combat_ready.emit(self, true, true)


func fwd_player_combat_not_ready():
	# who: Actor, thing: Variant, select: bool
	player_combat_not_ready.emit(self, false, false)

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


func enter_combat(contest: Contest):
	print("Player | Entering lander contest")
	player_ui.run_combat_display(contest)
	player_controller.enter_combat()


func fwd_combat_unit_selected(unit: UnitObject):
	# who: Actor, thing: UnitObject, select:bool
	combat_unit_selected.emit(self, unit, true)


func combat_update(contest: Contest):
	print("Player | Combat update recieved")
	if(contest.get_invading_actor() == self or contest.get_defending_actor() == self):
		player_ui.update_combat_display(contest)
		#player_controller.enter_combat()


func combat_outcome(c_out: Array[CombatOutcome]):
	#print("Player | Recieved Combat Outcome call")
	player_ui.combat_outcome(c_out)
	player_controller.exit_combat()


func fwd_next_phase_req(req: Action):
	req.actor = self
	next_phase_req.emit(req)


func game_phase_changed(game_phase):
	player_controller.game_phase_changed(game_phase)
	player_ui.game_phase_changed(game_phase)


func setup_turn_order_display():
	player_ui.setup_turn_order_display()


func actor_turn_changed(active_player: Actor):
	player_ui.actor_turn_changed(active_player)
	player_controller.actor_turn_changed(active_player)


func seasons_generated():
	player_ui.seasons_generated()


func season_changed(cur_sea: int):
	player_ui.season_changed(cur_sea)


func fwd_move_action_req(req: Action):
	req.set_actor(self)
	move_units_action_req.emit(req)


func fwd_purchase_action_req(req: Action):
	purchase_action_req.emit(req)


func fwd_close_market():
	close_market.emit()
