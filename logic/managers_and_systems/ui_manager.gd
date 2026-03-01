extends Control

# signals
signal build_action_req(build_req)
signal buy_unit_action_req(buy_unit_req)
signal move_units_action_req(move_units_req)
signal attack_action_req(req: Action)

# enums
#enum Element {EARTH,WATER,AIR,FIRE,}

# constants

# static variables
var turn_manager: GameManager

# @export variables

# remaining regular variables
var selector_manager:GameManager
var lander_manager: GameManager
var combat_manager: GameManager
var player_self: Player

# @onready variables
@onready var lander_panel:Panel = self.find_child("LanderPanel")
@onready var turn_panel: Panel = self.find_child("TurnPanel")
@onready var combat_panel: Panel = self.find_child("CombatPanel")

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
	lander_panel.move_units_action_req.connect(self.fwd_move_units_req)
	lander_panel.attack_action_req.connect(self.fwd_attack_action_req)

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


func bind_combat_manager(cm: GameManager):
	combat_manager = cm
	combat_panel.bind_combat_manager(cm)


func bind_player(p: Player):
	player_self = p
	for child in get_children():
		if child.has_method("bind_player"):
			child.bind_player(p)

func display_landers_req(lander: Lander):
	lander_panel.show()
	lander_panel.update()


func fwd_build_request(build_req: Action):
	build_action_req.emit(build_req)


func fwd_buy_unit_action_req(buy_unit_req: Action):
	buy_unit_action_req.emit(buy_unit_req)


func fwd_move_units_req(req: Action):
	move_units_action_req.emit(req)


func fwd_attack_action_req(req: Action):
	attack_action_req.emit(req)


## Calls
func received_build_action_completed(req: Action):
	lander_panel.update()


func fwd_buy_unit_action_completed(req: Action):
	lander_panel.update()

func fwd_move_units_action_completed(req: Action):
	selector_manager.clear_selected_units()
	selector_manager.set_target_lander(null)
	lander_panel.update()


func run_combat_display(contest: Contest):
	print("PlayerUI | run_combat_display recieved")
	lander_panel.hide()
	turn_panel.hide()

	combat_panel.show()
	combat_panel.setup_combat_display(contest)
