extends Control

# signals
signal build_action_req(build_req)
signal buy_unit_action_req(buy_unit_req)
signal move_units_action_req(move_units_req)
signal attack_action_req(req: Action)
signal unit_selected(unit: UnitObject)
signal unit_deslected(unit: UnitObject)
signal player_combat_ready
signal player_combat_not_ready
signal next_phase_req(req: Action)

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
@onready var players_panel: Panel = self.find_child("PlayersPanel")
@onready var seasons_panel: Panel = self.find_child("SeasonPanel")

###################################################################################################
###	Methods
func _ready() -> void:
	connect_signals()
	connect_wires()

	lander_panel.hide()
	combat_panel.hide()
		

### Signals and wires
func connect_signals():
	lander_panel.build_action_req.connect(self.fwd_build_request)
	lander_panel.buy_unit_action_req.connect(self.fwd_buy_unit_action_req)
	lander_panel.move_units_action_req.connect(self.fwd_move_units_req)
	lander_panel.attack_action_req.connect(self.fwd_attack_action_req)

	combat_panel.unit_selected.connect(self.fwd_unit_selected)
	combat_panel.unit_deslected.connect(self.fwd_unit_deslected)
	combat_panel.player_combat_ready.connect(self.fwd_player_combat_ready)
	combat_panel.player_combat_not_ready.connect(fwd_player_combat_not_ready)
	combat_panel.combat_display_toggled.connect(self.combat_display_toggled)
	combat_panel.attack_req.connect(self.fwd_attack_action_req)

	turn_panel.next_phase_req.connect(self.fwd_next_phase_req)


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
	for child in get_children():
		if child.has_method("bind_turn_manager"):
			child.bind_turn_manager(tm)


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


func fwd_player_combat_ready():
	player_combat_ready.emit()


func fwd_player_combat_not_ready():
	player_combat_not_ready.emit()


func fwd_next_phase_req(req: Action):
	next_phase_req.emit(req)

## Calls
func received_build_action_completed(req: Action):
	lander_panel.update()


func fwd_buy_unit_action_completed(req: Action):
	lander_panel.update()

func fwd_move_units_action_completed(req: Action):
	selector_manager.clear_selected_units()
	selector_manager.set_target_lander(null)
	lander_panel.update()


func fwd_unit_selected(unit: UnitObject):
	unit_selected.emit(unit)


func run_combat_display(contest: Contest):
	print("PlayerUI | run_combat_display recieved")
	lander_panel.hide()
	turn_panel.hide()

	combat_panel.show()
	combat_panel.setup_combat_display(contest)


func update_combat_display(contest: Contest):
	print("PlayerUI | update combat recieved")
	combat_panel.update_combat_display(contest)


func fwd_unit_deslected(unit: UnitObject):
	unit_deslected.emit(unit)


func combat_outcome(c_out: Array[CombatOutcome]):
	combat_panel.combat_outcome(c_out)


func game_phase_changed(game_phase):
	turn_panel.game_phase_changed(game_phase)


func setup_turn_order_display():
	players_panel.setup_turn_order_display()


func actor_turn_changed(active_actor: Actor):
	players_panel.actor_turn_changed(active_actor)


func seasons_generated():
	seasons_panel.seasons_generated()


func season_changed(sea_indx: int):
	seasons_panel.season_changed(sea_indx)


func combat_display_toggled(toggled_on: bool):
	if toggled_on:
		players_panel.show()
		turn_panel.show()
	else:
		turn_panel.hide()
		lander_panel.hide()
		players_panel.hide()
