# ui_manager.gd
# Controls flow between player and UI sections

class_name UIManager
extends Control

#region Signals
# Debug
signal build_action_req(build_req)
signal buy_unit_action_req(buy_unit_req)
# Movement
signal move_units_action_req(move_units_req)
signal attack_action_req(req: Action)
# Combat
signal unit_selected(unit: UnitObject)
signal unit_deslected(unit: UnitObject)
signal player_combat_ready
signal player_combat_not_ready
# Turn sys
signal next_phase_req(req: Action)
signal move_action_req(req: Action)
# Setup
signal setup_biome_pressed(b: BiomeData)
signal all_setup_landers_placed()
# Market
signal purchase_action_req(req)


#endregion

#region Runtime Refs
# static variables
var turn_manager: Node
var match_settings

# remaining regular variables
var selector_manager:Node
var lander_manager: Node
var combat_manager: Node
var player_self: Player
var player_wallet: EconData

# @onready variables
@onready var lander_panel:Panel = self.find_child("LanderPanel")
@onready var turn_panel: Panel = self.find_child("TurnPanel")
@onready var combat_panel: Panel = self.find_child("CombatPanel")
@onready var players_panel: Panel = self.find_child("PlayersPanel")
@onready var seasons_panel: Panel = self.find_child("SeasonPanel")
@onready var movement_panel: Panel = self.find_child("MovementPanel")
@onready var purchase_panel: Panel = self.find_child("PurchasePanel")
@onready var wallet_panel: Panel = self.find_child("WalletPanel")
@onready var setup_panel: Panel = self.find_child("SetupPanel")


#endregion

###################################################################################################
#region Lifecycle
func _ready() -> void:
	connect_signals()

	# Starting Hide/Show
	lander_panel.hide()
	combat_panel.hide()
	movement_panel.hide()


#endregion

#region Binders
func bind_selector(sm: Node):
	selector_manager = sm  # Bind self
	# Bind Children
	for child in get_children():
		if child.has_method("bind_selector"):
			child.bind_selector(sm)


func bind_turn_manager(tm: Node):
	turn_manager = tm # Bind self
	# Bind Children
	for child in get_children():
		if child.has_method("bind_turn_manager"):
			child.bind_turn_manager(tm)


func bind_lander_manager(lm: Node):
	lander_manager = lm # Bind self
	# Bind Children
	for child in get_children():
		if child.has_method("bind_lander_manager"):
			child.bind_lander_manager(lm)


func bind_combat_manager(cm: Node):
	combat_manager = cm # Bind self
	# Bind Children
	for child in get_children():
		if child.has_method("bind_combat_manager"):
			child.bind_combat_manager(cm)


func bind_player(p: Player):
	player_self = p # Bind self
	# Bind Children
	for child in get_children():
		if child.has_method("bind_player"):
			child.bind_player(p)


func bind_wallet(pw: EconData):
	player_wallet = pw # Bind self
	# Bind Children
	for child in get_children():
		if child.has_method("bind_wallet"):
			child.bind_wallet(pw)


func bind_match_settings(ms):
	match_settings = ms # Bind self
	# Bind Children
	for child in get_children():
		if child.has_method("bind_match_settings"):
			child.bind_match_settings(ms)


#endregion

#region Signal Connections
func connect_signals():
	# Lander
	lander_panel.build_action_req.connect(self.fwd_build_request) # Build Debug
	lander_panel.buy_unit_action_req.connect(self.fwd_buy_unit_action_req) #Buy Debug
	lander_panel.move_units_action_req.connect(self.fwd_move_units_req) # Movement
	lander_panel.attack_action_req.connect(self.fwd_attack_action_req) # Attack
	# Combat
	combat_panel.unit_selected.connect(self.fwd_unit_selected) # Unit Select
	combat_panel.unit_deslected.connect(self.fwd_unit_deslected) # Unit Deselect
	combat_panel.player_combat_ready.connect(self.fwd_player_combat_ready) # Combat Ready
	combat_panel.player_combat_not_ready.connect(self.fwd_player_combat_not_ready) # Combat Unready
	combat_panel.combat_display_toggled.connect(self.combat_display_toggled) # Combat Show/Hide
	combat_panel.attack_req.connect(self.fwd_attack_action_req) # Attack
	combat_panel.combat_ui_closed.connect(self.combat_ui_closed) # Close Combat
	# Turn
	turn_panel.next_phase_req.connect(self.fwd_next_phase_req) # Next phase
	# Movement
	movement_panel.move_action_req.connect(self.fwd_move_action_req) # MOvement
	# Purchase
	purchase_panel.purchase_action_req.connect(self.fwd_purchase_action_req) # Purchase
	purchase_panel.close_market.connect(self.fwd_close_market) # Close Market
	# Setup
	setup_panel.setup_biome_pressed.connect(self.fwd_setup_biome_pressed) # Biome Btn pressed
	setup_panel.all_setup_landers_placed.connect(self.fwd_all_setup_landers_placed) # All Biopmes placed


#endregion

#region Forwarders
# Debug
func fwd_build_request(build_req: Action):
	build_action_req.emit(build_req)


func fwd_buy_unit_action_req(buy_unit_req: Action):
	buy_unit_action_req.emit(buy_unit_req)


func fwd_buy_unit_action_completed(req: Action):
	lander_panel.update()


# Lander
# Combat
func fwd_attack_action_req(req: Action):
	attack_action_req.emit(req)


func fwd_player_combat_ready():
	player_combat_ready.emit()


func fwd_player_combat_not_ready():
	player_combat_not_ready.emit()


# Turn
func fwd_next_phase_req(req: Action):
	next_phase_req.emit(req)


# Movement
func fwd_move_units_req(req: Action):
	move_units_action_req.emit(req)


func fwd_move_units_action_completed(req: Action):
	selector_manager.clear_selected_units()
	selector_manager.set_target_lander(null)
	lander_panel.update()


func fwd_unit_selected(unit: UnitObject):
	unit_selected.emit(unit)


func fwd_unit_deslected(unit: UnitObject):
	unit_deslected.emit(unit)


func fwd_move_action_req(req: Action):
	move_action_req.emit(req)


# Purchase
func fwd_purchase_action_req(req: Action):
	purchase_action_req.emit(req)


func fwd_close_market():
	if turn_manager.get_game_phase() == turn_manager.GameLoop.BUYING_PHASE:
		var new_action = Action.new()
		new_action.set_type(Action.RequestType.PROGRESS_TURN)
		next_phase_req.emit(new_action)


# Setup

func fwd_setup_biome_pressed(b: BiomeData):
	setup_biome_pressed.emit(b)


func fwd_all_setup_landers_placed():
	all_setup_landers_placed.emit()


#endregion

#region Callbacks
# Debug
func display_landers_req(lander: Lander):
	lander_panel.show()
	lander_panel.update()


func received_build_action_completed(req: Action):
	lander_panel.update()


# lander
# Turn
func game_phase_changed(game_phase):
	turn_panel.game_phase_changed(game_phase)

	match game_phase:
		turn_manager.GameLoop.UPKEEP:
			pass
		turn_manager.GameLoop.DUSTCLOUD_COLLASPE_PHASE:
			pass
		turn_manager.GameLoop.BUYING_PHASE:
			if turn_manager.get_active_actor() == player_self:
				purchase_panel.run_market()
		turn_manager.GameLoop.COMBAT_PHASE:
			if turn_manager.get_active_actor() == player_self:
				purchase_panel.hide()
		turn_manager.GameLoop.CLEANUP:
			pass	


func game_state_changed(game_state):
	for child in self.get_children():
		if child.has_method("game_state_changed"):
			child.game_state_changed(game_state)


# Combat
func run_combat_display(contest: Contest):
	print("PlayerUI | run_combat_display recieved")
	lander_panel.hide()
	turn_panel.hide()

	combat_panel.show()
	combat_panel.setup_combat_display(contest)


func update_combat_display(contest: Contest):
	print("PlayerUI | update combat recieved")
	combat_panel.update_combat_display(contest)


func combat_outcome(c_out: Array[CombatOutcome]):
	combat_panel.combat_outcome(c_out)


func combat_display_toggled(toggled_on: bool):
	if toggled_on:
		players_panel.show()
		turn_panel.show()
	else:
		turn_panel.hide()
		lander_panel.hide()
		players_panel.hide()


func combat_ui_closed():
	turn_panel.show()


# Players
func setup_turn_order_display():
	players_panel.setup_turn_order_display()


func actor_turn_changed(active_actor: Actor):
	players_panel.actor_turn_changed(active_actor)


# Seasons
func seasons_generated():
	seasons_panel.seasons_generated()


func season_changed(sea_indx: int):
	seasons_panel.season_changed(sea_indx)


# Movement
# Purchase
func run_movement(from: Lander, to: Lander):
	#print("Player UI | Call | Run movement UI call")
	movement_panel.run_movement(from, to)


# Wallet
func econ_changed():
	wallet_panel.econ_changed()


# End Of File
