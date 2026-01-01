extends Node

# signals

# enums

# constants

# static variables
var player_scene = preload("res://sences/player.tscn")

# @export variables

# remaining regular variables

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_actors()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Funcs()
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
	pass
