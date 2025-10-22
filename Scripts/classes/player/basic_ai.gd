class_name bAi
extends character

# signals

# enums

# constants

# static variables

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("New AI here :3")
	
	connect_signals()
	player_resources.gold = 3000
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func init_rnd_race():
	init_race(data_player.rnd_race())

func generate_starting_terrian():
	print(str(name) + " is generating starting terrinan ... ")

### Connected Signals
