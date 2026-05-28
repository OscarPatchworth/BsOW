## game_root.gd
## Root node in a game scene. Setups: managers, players, binds and wires them.

###################################################################################################
class_name GameRoot
extends Node

#region Values
# signals
signal root_setup_finished

# Scene Refs
var player_sence = preload("res://sences/player.tscn")
var lander_sence = preload("res://sences/landerSene.tscn")
#var match_settings_data = preload("res://data/match_settings.gd")

# enums

# constants

# static variables

# @export variables
@export var game_species: Array[SpeciesData]
@export var biome_types: Array[BiomeData]

# regular variables
	# Runtime Refs
var action_manager: Node
var lander_manager: Node
var turn_manager: Node
var combat_manager: Node
var player_manager: Node
var draw_3d: Node
#var match_settings: Node

# @onready variables
@onready var managers_node = self.find_child("Managers")
@onready var players_node = self.find_child("Actors")
@onready var landers_sence_node = self.find_child("Landers")
@onready var match_settings = self.find_child("MatchSettings")


#endregion
###################################################################################################
#region Lifecycle
func _ready() -> void:
	instance_managers()
	init_game_managers_and_systems()
	add_actors()
	root_setup_finished.emit()


#endregion

#region Setup Flow
	# Manager Setup
func instance_managers():
	# Action Manager
	action_manager = ActionManager.new()
	managers_node.add_child(action_manager)
	# Lander Manager
	lander_manager = LanderManager.new()
	managers_node.add_child(lander_manager)
	# Turn Manager
	turn_manager = TurnManager.new()
	managers_node.add_child(turn_manager)
	# Combat Manager
	combat_manager = CombatManager.new()
	managers_node.add_child(combat_manager)
	# Actors Manager
	player_manager = PlayerManager.new()
	managers_node.add_child(player_manager)
	# Draw3D
	draw_3d = Draw3D.new()
	managers_node.add_child(draw_3d)


func init_game_managers_and_systems():
	init_action_manager()
	init_lander_manager()
	init_turn_manager()
	init_combat_manager()


func init_action_manager():
	bind_to_action_manager()
	wire_from_action_manager()


func init_lander_manager():
	bind_to_lander_manager()
	wire_from_lander_manager()


func init_turn_manager():
	bind_to_turn_manager()
	wire_from_turn_manager()


func init_combat_manager():
	bind_to_combat_manager()
	wire_from_combat_manager()


# Player Setup
func add_actors():
	add_players()
	add_ai()


func add_players():
	var player_x = player_sence.instantiate()
	setup_player(player_x)
	players_node.add_child(player_x)


func add_ai():
	var new_ai = SimpleAI.new()
	players_node.add_child(new_ai)
	setup_ai(new_ai)

#endregion

#region Player Init
func setup_player(player_x):
	# setup temp vars
	var player_cntrl = player_x.find_child("PlayerController")
	# Binders
	turn_manager.bind_actor_to_actor_group(player_x)
	player_cntrl.action_manager = action_manager
	player_x.turn_manager = self.turn_manager
	player_x.lander_manager = self.lander_manager
	player_x.combat_manager = self.combat_manager
	player_x.draw_3d = self.draw_3d
	player_x.match_settings = self.match_settings

	# Connect Signals
	# FROM self_player
	# To Action Manager
	player_x.build_action_req.connect(action_manager.action_request) # Build
	player_x.buy_unit_action_req.connect(action_manager.action_request) # Buy Unit
	player_x.move_units_action_req.connect(action_manager.action_request) # Move units
	player_x.attack_action_req.connect(action_manager.action_request) # Attack
	player_x.purchase_action_req.connect(action_manager.action_request) # Purchase
	player_x.next_phase_req.connect(action_manager.action_request) # Progress turn
	player_x.place_biome_req.connect(action_manager.action_request) # Place Biome
	player_x.place_command_tower.connect(action_manager.action_request) # Place CT
	# To Combat Manager
	player_x.combat_unit_selected.connect(combat_manager.actor_selection_req) # Select Units
	player_x.unit_deslected.connect(combat_manager.actor_selection_req) # Deselect Units
	player_x.player_combat_ready.connect(combat_manager.actor_selection_req) # Combat Ready
	player_x.player_combat_not_ready.connect(combat_manager.actor_selection_req) # Combat UnReady

	# TO self_player
	# From Lander Manager
	lander_manager.built_action_completed.connect(player_x.fwd_build_action_completed) #  BuildA complete
	lander_manager.buy_unit_action_completed.connect(player_x.fwd_buy_unit_action_completed) # BuyA complete
	lander_manager.move_units_action_completed.connect(player_x.fwd_move_units_action_completed) # MoveA complete
	# From Turn Manager
	turn_manager.game_phased_changed.connect(player_x.game_phase_changed) # Game Phase delta
	turn_manager.turn_order_generated.connect(player_x.setup_turn_order) # Turn Order gen
	turn_manager.actor_turn_changed.connect(player_x.actor_turn_changed) # Actor Turn delta
	turn_manager.season_order_generated.connect(player_x.seasons_generated) # Season gen
	turn_manager.season_changed.connect(player_x.season_changed) # Season delta
	turn_manager.current_game_state.connect(player_x.game_state_changed) # Game State delta
	# From Combat Manager
	combat_manager.combat_started.connect(player_x.enter_combat) # Combat Started
	combat_manager.combat_updated.connect(player_x.combat_update) # Combat updated
	combat_manager.combat_outcome.connect(player_x.combat_outcome) # Combat Outcome
	# From Action Manager	
	action_manager.place_biome.connect(func(req): if req.actor == player_x:  # Placed Setup Biome
		if turn_manager.get_game_state() == turn_manager.GameSequence.SETUP: 
			return player_x.setup_biome_placed(req))
	action_manager.build_action.connect(func(req): if req.actor == player_x:  # Build Setup CT
		if turn_manager.get_game_state() == turn_manager.GameSequence.SETUP: 
			return player_x.command_tower_placed())

	# Setup Player Settings
	player_x.species = game_species.pick_random() # Species
	# Wallet
	player_x.wallet = EconData.new()	
	player_x.wallet.set_resource_value("gold", 10)
	player_x.wallet.set_resource_value("food", 10)
	player_x.wallet.set_resource_value("mineral", 10)
	player_x.wallet.set_resource_value("wood", 10)
	player_x.wallet.set_resource_value("stone", 10)

#endregion


#region AI Init
func setup_ai(sai: SimpleAI):
	# Setup temp vars

	# Binders
	turn_manager.bind_actor_to_actor_group(sai)
	sai.turn_manager = self.turn_manager
	sai.lander_manager = self.lander_manager
	sai.combat_manager = self.combat_manager

	# Signals
	# To
	combat_manager.combat_started.connect(sai.combat_req)
	combat_manager.combat_updated.connect(sai.combat_update)
	# From
	sai.combat_unit_selected.connect(combat_manager.actor_selection_req)
	sai.unit_deslected.connect(combat_manager.actor_selection_req)
	sai.combat_ready.connect(combat_manager.actor_selection_req)
	sai.combat_not_ready.connect(combat_manager.actor_selection_req)

	# Setup AI settings
	sai.species = game_species.pick_random() # Species
	# Wallet
	sai.wallet = EconData.new()
	sai.wallet.set_resource_value("gold", 10)
	sai.wallet.set_resource_value("food", 10)
	sai.wallet.set_resource_value("mineral", 10)
	sai.wallet.set_resource_value("wood", 10)
	sai.wallet.set_resource_value("stone", 10)

	# Temp fix
	# Init Landers
	for i in match_settings.starting_simple_troops:
		var place_pos = Vector3.ZERO
		place_pos.x = randf() * match_settings.map_size * ((-1)**(randi()%2))
		place_pos.z = randf() * match_settings.map_size * ((-1)**(randi()%2))
		if lander_manager.is_pos_min_distance_apart(place_pos):
			lander_manager.spawn_protected_lander(place_pos, sai, match_settings.starting_simple_troops )
		else:
			print("AI init lander spawn error: out of bounds")


#endregion

#region Binders
func bind_to_action_manager():
	action_manager.lander_manager = self.lander_manager
	action_manager.turn_manager = self.turn_manager
	action_manager.combat_manager = self.combat_manager


func bind_to_lander_manager():
	# Bind Scenes
	lander_manager.lander_sence = self.lander_sence
	# Bind nodes
	lander_manager.landers_sence_node = self.landers_sence_node
	# Bind Values
	lander_manager.biome_types = self.biome_types
	lander_manager.biome_types = self.biome_types
	lander_manager.connected_lander_distance = 3


func bind_to_turn_manager():
	# Bind nodes
	turn_manager.actors = players_node.get_children()


func bind_to_combat_manager():
	# Bind Managers
	combat_manager.bind_match_settings(match_settings)


#endregion

#region Signal Connections
func wire_from_action_manager():
	action_manager.progress_turn.connect(turn_manager.progress_turn)
	action_manager.build_action.connect(lander_manager.build_action)
	action_manager.buy_unit_action.connect(lander_manager.buy_unit_action)
	action_manager.place_biome.connect(lander_manager.inst_biome)
	# Conditional wire
	action_manager.build_action.connect(func(req): if turn_manager.get_game_state() == turn_manager.GameSequence.SETUP: 
		return await turn_manager.actor_finished_setup(req.actor))


func wire_from_lander_manager():
	pass


func wire_from_turn_manager():
	# Condtional wire
	turn_manager.game_phased_changed.connect(func(phase): 
		if phase == turn_manager.GameLoop.UPKEEP: lander_manager.run_upkeep(turn_manager.get_active_actor()))
	# Wire TO turn manager
	self.root_setup_finished.connect(turn_manager.self_init)

	
func wire_from_combat_manager():
	combat_manager.combat_started.connect(turn_manager.combat_started)
	combat_manager.bind_match_settings(match_settings)


#endregion


# End of File
