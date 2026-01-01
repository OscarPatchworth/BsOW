extends Node

# signals

# enums

# constants

# static variables
### Loadable sences
var player_scene = preload("res://sences/player.tscn")

# @export variables

# remaining regular variables

# @onready vars
### Managers
@onready var action_manager = self.find_child("ActionManager")
@onready var lander_manager = self.find_child("LanderManager")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_game_managers_and_systems()
	init_actors()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Funcs()
# Init Game Managers
func init_game_managers_and_systems():
	init_action_manager()


func init_action_manager():
	action_manager.lander_manager = lander_manager


# Init Actors
func init_actors():
	add_player()
	add_ai()


func add_player():
	var actor_node = find_child("Actors")
	var player_x = player_scene.instantiate()
	actor_node.add_child(player_x)
	init_player(player_x)


func add_ai():
	pass


func init_player(player_x: Player):
	#player.refrence = wire
	var camera = find_child("Camera3D")
	var player_cntrl = player_x.find_child("PlayerController")
	player_cntrl.cam = camera
	player_cntrl.action_manager = action_manager
	pass
