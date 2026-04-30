#player.gd
# A player obj thatn holds player data and co-ordenates, player ui, player controller and the rest of the game

class_name Player
extends Actor


#region Signals
# Market
signal build_action_req(build_req: Action)
signal buy_unit_action_req(buy_unit_req: Action)
signal purchase_action_req(req: Action)
signal close_market()

# Movement
signal move_units_action_req(move_units_req: Action)
signal attack_action_req(req: Action)

# Combat
signal combat_unit_selected(who: Actor, thing: UnitObject, select:bool)
signal unit_deslected(who: Actor, thing: UnitObject, select:bool)
signal player_combat_ready(who: Actor, thing: Variant, select: bool)
signal player_combat_not_ready(who: Actor, thing: Variant, select: bool)

# Turn sys
signal next_phase_req(req: Action)
signal place_biome_req(req: Action)
signal place_command_tower(req: Action)


#endregion
#region Runtime Refs

# static variables
var draw_3d: Draw3D
var match_settings

# @onready variables
@onready var player_controller: Node = self.find_child("PlayerController")
@onready var player_ui: Control = self.find_child("UI-manager")
@onready var selector_manager:Node = self.find_child("SelectorManager")


#endregion

###################################################################################################
#region Lifecycle
func _ready() -> void:
	connect_wires()
	connect_signals()

func connect_wires():
	bind_selector_manager()
	bind_turn_manager()
	bind_lander_manager()
	bind_combat_manager()
	bind_self()
	bind_wallet()
	bind_draw_3d()
	bind_match_settings()


func connect_signals():
	connect_controller_signals()
	connect_ui_signals()
	connect_misc_signals()


#endregion

#region Binders
func bind_selector_manager():
	# Wire selector: manager->Things
	player_controller.selector_manager = selector_manager
	player_ui.bind_selector(selector_manager)
	# Wire selector: Things->Manager
	selector_manager.self_player = self


func bind_turn_manager():
	# Wire: manager -> Things
	player_ui.bind_turn_manager(turn_manager)
	player_controller.bind_turn_manager(turn_manager)


func bind_lander_manager():
	# Wire: manager -> Things
	player_ui.bind_lander_manager(lander_manager)
	player_controller.bind_lander_manager(lander_manager)


func bind_combat_manager():
	# Wire: manager -> Things
	player_ui.bind_combat_manager(combat_manager)


func bind_self():
	player_ui.bind_player(self)
	player_controller.bind_player(self)

func bind_wallet():
	player_ui.bind_wallet(wallet)


func bind_draw_3d():
	player_controller.draw_3d = draw_3d


func bind_match_settings():
	player_ui.bind_match_settings(match_settings)

#endregion

#region Signal Connections
func connect_controller_signals():
	# Redirect to UI
	player_controller.view_lander_requested.connect(player_ui.display_landers_req) # View Lander Debug
	player_controller.run_movement_ui.connect(player_ui.run_movement) # Run movement UI
	# Misc
	player_controller.select_lander.connect(selector_manager.select_lander_req) # Add to selector
	# Forwarders
	player_controller.attack_action_req.connect(self.fwd_attack_action_req) # Fwd Attack
	player_controller.place_biome_req.connect(self.fwd_place_biome_req) # Fwd Biome place
	player_controller.place_command_tower.connect(self.fwd_place_command_tower) # Fwd CT place


func connect_ui_signals():
	# Redirect to Controller
	player_ui.setup_biome_pressed.connect(player_controller.setup_biome_pressed) # Setup Biome toggle
	player_ui.all_setup_landers_placed.connect(player_controller.all_setup_landers_placed) # All Setup landers placed event
	# Misc
	# Forwarders
	player_ui.build_action_req.connect(self.fwd_build_req) # Fwd build Debug
	player_ui.buy_unit_action_req.connect(self.fwd_buy_unit_action_req) # Fwd Buy Debug
	player_ui.move_units_action_req.connect(self.fwd_move_units_req) # Fwd Move Debug
	player_ui.attack_action_req.connect(self.fwd_attack_action_req) # Fwd Attack
	player_ui.unit_selected.connect(self.fwd_combat_unit_selected) # Fwd Unit Select
	player_ui.unit_deslected.connect(self.fwd_unit_deslected) # Fwd Unit Deselect
	player_ui.player_combat_ready.connect(self.fwd_player_combat_ready) # Fwd Comabat Ready
	player_ui.player_combat_not_ready.connect(self.fwd_player_combat_not_ready) # Fwd Combat Unready
	player_ui.next_phase_req.connect(self.fwd_next_phase_req) # Fwd progress tunr
	player_ui.move_action_req.connect(self.fwd_move_action_req) # Fwd Move
	player_ui.purchase_action_req.connect(self.fwd_purchase_action_req) # Fwd Purchase



func connect_misc_signals():
	wallet.econ_changed.connect(player_ui.econ_changed)


#endregion

#region Forwarders
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


func fwd_combat_unit_selected(unit: UnitObject):
	# who: Actor, thing: UnitObject, select:bool
	combat_unit_selected.emit(self, unit, true)


func fwd_next_phase_req(req: Action):
	req.actor = self
	next_phase_req.emit(req)


func fwd_move_action_req(req: Action):
	req.set_actor(self)
	move_units_action_req.emit(req)


func fwd_purchase_action_req(req: Action):
	purchase_action_req.emit(req)


func fwd_close_market():
	close_market.emit()


func fwd_place_biome_req(req: Action):
	req.actor = self
	place_biome_req.emit(req)

func fwd_place_command_tower(req: Action):
	req.actor = self
	req.building_type = self.species.command_tower
	place_command_tower.emit(req)


#endregion

#region Callbacks
func enter_combat(contest: Contest):
	print("Player | Entering lander contest")
	player_ui.run_combat_display(contest)
	player_controller.enter_combat()


func combat_update(contest: Contest):
	print("Player | Combat update recieved")
	if(contest.get_invading_actor() == self or contest.get_defending_actor() == self):
		player_ui.update_combat_display(contest)
		#player_controller.enter_combat()


func combat_outcome(c_out: Array[CombatOutcome]):
	#print("Player | Recieved Combat Outcome call")
	player_ui.combat_outcome(c_out)
	player_controller.exit_combat()


func game_phase_changed(game_phase):
	player_controller.game_phase_changed(game_phase)
	player_ui.game_phase_changed(game_phase)


func game_state_changed(game_state):
	player_controller.game_state_changed(game_state)
	player_ui.game_state_changed(game_state)


func setup_turn_order():
	player_ui.setup_turn_order_display()
	if turn_manager.get_active_actor() == self:
		player_controller.set_is_active_player(true)


func actor_turn_changed(active_player: Actor):
	player_ui.actor_turn_changed(active_player)
	player_controller.actor_turn_changed(active_player)


func seasons_generated():
	player_ui.seasons_generated()


func season_changed(cur_sea: int):
	player_ui.season_changed(cur_sea)


func command_tower_placed():
	player_controller.command_tower_placed()


#endregion

#region State 
# Gettets
func get_starting_biomes() -> Array:
	return species.starting_landers

# Setters


#endregion


# End Of File
