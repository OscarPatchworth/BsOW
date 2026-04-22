## game_root.gd
## Root node in a game scene. Setups: managers, players, binds and wires them.

###################################################################################################
class_name GameRoot
extends Node

#region Value
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
	init_actors()
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
	managers_node.add_child(action_manager)
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
func init_actors():
	add_players()
	add_ai()


func add_players() 	:
	pass


func add_ai():
	pass
	
		
#endregion

#region Binders
func bind_to_action_manager():
	pass


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

#region Forwarders

#endregion

#region Callbacks

#endregion

#region State Queries

#endregion

#region Helpers

#endregion








