extends Node

# signals

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

### Sence Nodes
@onready var landers_sence_node = self.find_child("Landers")


###################################################################################################
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_game_managers_and_systems()
	init_actors()
	

###################################################################################################
### Custom Funcs()
# Init Game Managers
func init_game_managers_and_systems():
	init_action_manager()
	init_lander_manager()
	init_turn_manager()
	init_combat_manager()


# Init action manager
func init_action_manager():
	# Connect Wires
	action_manager.lander_manager = lander_manager
	action_manager.combat_manager = combat_manager


# Init lander manager
func init_lander_manager():
	lander_manager.landers_sence_node = self.landers_sence_node
	lander_manager.inst_lander(Vector3.ZERO)
	
	# Connect Signals
	action_manager.build_action.connect(lander_manager.build_action)
	action_manager.buy_unit_action.connect(lander_manager.buy_unit_action)


## Init turn manager
func init_turn_manager():
	# Connect Binders

	# Connect Signals
	combat_manager.combat_started.connect(turn_manager.combat_started)
	pass


# Init combat manager
func init_combat_manager():
	# Connect Binders
	combat_manager.bind_match_settings(match_settings)

	# Connect Signals



# Init Actors
func init_actors():
	add_player()
	add_ai()


func add_player():
	var actor_node = find_child("Actors")
	var player_x = player_scene.instantiate()
	init_player(player_x)
	actor_node.add_child(player_x)
	


func add_ai():
	#print("Number of opponents this match: " + str(match_settings.number_of_opponents))
	var actor_node = find_child("Actors")
	var new_ai = SimpleAI.new()
	init_ai(new_ai)
	actor_node.add_child(new_ai)



func init_ai(sai: SimpleAI):
	#print(ai)
	# AI congif
	sai.species = game_species.pick_random()

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
	# player.refrence = wire
	var player_cntrl = player_x.find_child("PlayerController")
	player_cntrl.action_manager = action_manager
	player_x.turn_manager = self.turn_manager
	player_x.lander_manager = self.lander_manager
	player_x.combat_manager = self.combat_manager

	# Connect Signals
	# FROM player
	player_x.build_action_req.connect(action_manager.action_request)
	player_x.buy_unit_action_req.connect(action_manager.action_request)
	player_x.move_units_action_req.connect(action_manager.action_request)
	player_x.attack_action_req.connect(action_manager.action_request)
	player_x.combat_unit_selected.connect(combat_manager.actor_selected_unit)
	player_x.unit_deslected.connect(combat_manager.actor_deselected_unit)
	#player_x.player_combat_ready.connect(combat_manager.player_ready)
	#player_x.player_combat_not_ready.connect(combat_manager.player_unready)
	player_x.player_combat_ready.connect(combat_manager.actor_selection_req)
	player_x.player_combat_not_ready.connect(combat_manager.actor_selection_req)
	

	# TO player
	lander_manager.built_action_completed.connect(player_x.fwd_build_action_completed)
	lander_manager.buy_unit_action_completed.connect(player_x.fwd_buy_unit_action_completed)
	lander_manager.move_units_action_completed.connect(player_x.fwd_move_units_action_completed)
	# turn_manager.combat_assign.connect(player_x.contest_lander)
	combat_manager.combat_started.connect(player_x.combat_req)
	combat_manager.combat_updated.connect(player_x.combat_update)
	# combat_update
	combat_manager.combat_outcome.connect(player_x.combat_outcome)

	player_x.species = game_species.pick_random()
	#print("Player Species randomly selected: " + str(player_x.species.name))
