extends Node

# signals
signal root_setup_finished
# enums

# constants

# static variables
### Loadable sences
var player_scene = preload("res://sences/player.tscn")

# @export variables
@export var game_species: Array[SpeciesData]
# remaining regular variables

# @onready vars
### Managers
@onready var action_manager = self.find_child("ActionManager")
@onready var lander_manager = self.find_child("LanderManager")
@onready var turn_manager = self.find_child("TurnManager")
@onready var match_settings = self.find_child("MatchSettings")
@onready var combat_manager = self.find_child("CombatManager")
@onready var actors_node = self.find_child("Actors")
@onready var draw_3d = self.find_child("Draw3D")
### Sence Nodes
@onready var landers_sence_node = self.find_child("Landers")


###################################################################################################
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_game_managers_and_systems()
	init_actors()
	root_setup_finished.emit()
	

###################################################################################################
### Custom Funcs()
# Init Game Managers
func init_game_managers_and_systems():
	init_action_manager()
	init_lander_manager()
	init_turn_manager()
	init_combat_manager()
	run_binders()


# Init action manager
func init_action_manager():
	# Connect Wires
	action_manager.lander_manager = lander_manager
	action_manager.combat_manager = combat_manager
	action_manager.turn_manager = turn_manager


# Init lander manager
func init_lander_manager():
	lander_manager.landers_sence_node = self.landers_sence_node
	lander_manager.inst_lander(Vector3.ZERO)
	
	# Connect Signals
	action_manager.build_action.connect(lander_manager.build_action)
	action_manager.buy_unit_action.connect(lander_manager.buy_unit_action)
	turn_manager.game_phased_changed.connect(func(phase): 
		if phase == turn_manager.GameLoop.UPKEEP: lander_manager.run_upkeep(turn_manager.get_active_actor()))


## Init turn manager
func init_turn_manager():
	# Connect Binders
	# Connect Signals
	combat_manager.combat_started.connect(turn_manager.combat_started)
	action_manager.progress_turn.connect(turn_manager.progress_turn)
	self.root_setup_finished.connect(turn_manager.self_init)

# Init combat manager
func init_combat_manager():
	# Connect Binders
	combat_manager.bind_match_settings(match_settings)

	# Connect Signals


# Run binders
func run_binders():
	pass	

# Init Actors
func init_actors():
	add_player()
	add_ai()


func add_player():
	var actor_node = find_child("Actors")
	var player_x = player_scene.instantiate()
	init_player(player_x)
	actor_node.add_child(player_x)

	turn_manager.bind_actor_to_actor_group(player_x)


func add_ai():
	#print("Number of opponents this match: " + str(match_settings.number_of_opponents))
	var actor_node = find_child("Actors")
	var new_ai = SimpleAI.new()
	init_ai(new_ai)
	actor_node.add_child(new_ai)

	turn_manager.bind_actor_to_actor_group(new_ai)


func init_ai(sai: SimpleAI):
	#print(ai)
	# AI congif
	sai.species = game_species.pick_random()
	sai.wallet = EconData.new()
	sai.wallet.set_resource_value("gold", 10)
	sai.wallet.set_resource_value("food", 10)
	sai.wallet.set_resource_value("mineral", 10)
	sai.wallet.set_resource_value("wood", 10)
	sai.wallet.set_resource_value("stone", 10)


	# Wires
	sai.turn_manager = self.turn_manager
	sai.lander_manager = self.lander_manager
	sai.combat_manager = self.combat_manager

	# Signals
	# TO sai
	combat_manager.combat_started.connect(sai.combat_req)
	combat_manager.combat_updated.connect(sai.combat_update)
	# FROM sai
	sai.combat_unit_selected.connect(combat_manager.actor_selected_unit)
	sai.unit_deslected.connect(combat_manager.actor_deselected_unit)
	sai.combat_ready.connect(combat_manager.player_ready)
	sai.combat_not_ready.connect(combat_manager.player_unready)

	# Init Landers
	for i in match_settings.starting_simple_troops:
		var place_pos = Vector3.ZERO
		place_pos.x = randf() * match_settings.map_size * ((-1)**(randi()%2))
		place_pos.z = randf() * match_settings.map_size * ((-1)**(randi()%2))
		if lander_manager.is_pos_min_distance_apart(place_pos):
			lander_manager.spawn_protected_lander(place_pos, sai, match_settings.starting_simple_troops )
		else:
			print("AI init lander spawn error: out of bounds")
		



func init_player(player_x: Player):
	# self_player.refrence = wire
	var player_cntrl = player_x.find_child("PlayerController")
	player_cntrl.action_manager = action_manager
	player_x.turn_manager = self.turn_manager
	player_x.lander_manager = self.lander_manager
	player_x.combat_manager = self.combat_manager
	player_x.draw_3d = self.draw_3d

	# Connect Signals
	# FROM self_player
	player_x.build_action_req.connect(action_manager.action_request)
	player_x.buy_unit_action_req.connect(action_manager.action_request)
	player_x.move_units_action_req.connect(action_manager.action_request)
	player_x.attack_action_req.connect(action_manager.action_request)
	player_x.purchase_action_req.connect(action_manager.action_request)
	#player_x.combat_unit_selected.connect(combat_manager.actor_selected_unit)
	#player_x.unit_deslected.connect(combat_manager.actor_deselected_unit)
	player_x.combat_unit_selected.connect(combat_manager.actor_selection_req)
	player_x.unit_deslected.connect(combat_manager.actor_selection_req)
	#player_x.player_combat_ready.connect(combat_manager.player_ready)
	#player_x.player_combat_not_ready.connect(combat_manager.player_unready)
	player_x.player_combat_ready.connect(combat_manager.actor_selection_req)
	player_x.player_combat_not_ready.connect(combat_manager.actor_selection_req)
	player_x.next_phase_req.connect(action_manager.action_request)

	# TO self_player
	lander_manager.built_action_completed.connect(player_x.fwd_build_action_completed)
	lander_manager.buy_unit_action_completed.connect(player_x.fwd_buy_unit_action_completed)
	lander_manager.move_units_action_completed.connect(player_x.fwd_move_units_action_completed)
	# turn_manager.combat_assign.connect(player_x.contest_lander)
	combat_manager.combat_started.connect(player_x.enter_combat)
	combat_manager.combat_updated.connect(player_x.combat_update)
	# combat_update
	combat_manager.combat_outcome.connect(player_x.combat_outcome)
	turn_manager.game_phased_changed.connect(player_x.game_phase_changed)
	turn_manager.turn_order_generated.connect(player_x.setup_turn_order)
	turn_manager.actor_turn_changed.connect(player_x.actor_turn_changed)
	turn_manager.season_order_generated.connect(player_x.seasons_generated)
	turn_manager.season_changed.connect(player_x.season_changed)
	turn_manager.current_game_state.connect(player_x.game_state_changed)


	player_x.species = game_species.pick_random()
	#print("Player Species randomly selected: " + str(player_x.species.name))
	player_x.wallet = EconData.new()
	player_x.wallet.set_resource_value("gold", 10)
	player_x.wallet.set_resource_value("food", 10)
	player_x.wallet.set_resource_value("mineral", 10)
	player_x.wallet.set_resource_value("wood", 10)
	player_x.wallet.set_resource_value("stone", 10)
