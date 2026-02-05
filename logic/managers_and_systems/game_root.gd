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

### Sence Nodes
@onready var landers_sence_node = self.find_child("Landers")


###################################################################################################
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_actors()
	init_game_managers_and_systems()
	

###################################################################################################
### Custom Funcs()
# Init Game Managers
func init_game_managers_and_systems():
	init_action_manager()
	init_lander_manager()
	init_turn_manager()


# Init action manager
func init_action_manager():
	# Connect Wires
	action_manager.lander_manager = lander_manager


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
	


func add_ai():
	pass


func init_player(player_x: Player):
	# player.refrence = wire
	var player_cntrl = player_x.find_child("PlayerController")
	player_cntrl.action_manager = action_manager
	player_x.turn_manager = self.turn_manager
	player_x.lander_manager = self.lander_manager

	# Connect Signals
	player_x.build_action_req.connect(action_manager.action_request)
	player_x.buy_unit_action_req.connect(action_manager.action_request)
	player_x.move_units_action_req.connect(action_manager.action_request)

	lander_manager.built_action_completed.connect(player_x.fwd_build_action_completed)
	lander_manager.buy_unit_action_completed.connect(player_x.fwd_buy_unit_action_completed)

	player_x.species = game_species.pick_random()
	#print("Player Species randomly selected: " + str(player_x.species.name))
