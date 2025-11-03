class_name bAi
extends character

# signals

# enums

# constants

# static variables

# @export variables

# remaining regular variables

# @onready variables
var rng = RandomNumberGenerator.new()

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("New AI here :3")
	
	connect_signals()
	player_resources.gold = 3000
	
	lander_collision_a3d = load(data_node_ref.LANDER_COLLISION_A3D)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


### Custom Methods
func init_rnd_race():
	init_race(data_player.rnd_race())

func generate_starting_terrian():
	print(str(name) + " is generating starting terrinan ... ")
	var check_collision_area = Area3D.new()
	var check_collision_shape = CollisionShape3D.new()
	check_collision_shape.shape = CylinderShape3D.new()
	check_collision_shape.shape.height = 0.5
	check_collision_shape.shape.radius = 0.5
	check_collision_area.add_child(check_collision_shape)
	add_child(check_collision_area)

	check_collision_area.set_collision_mask_value(1, true)
	check_collision_area.set_collision_mask_value(2, true)
	check_collision_area.set_collision_mask_value(3, true)

	check_collision_area.global_transform.origin = Vector3(
		rng.randi_range(-20, 20),
		0,
		rng.randi_range(-20, 20)
	)
	check_collision_area.set_monitoring(true)

	var temp_loop = true
	
	while(temp_loop):
		if(check_collision_area.has_overlapping_bodies()):
			check_collision_area.global_transform.origin = Vector3(
				rng.randf_range(-20, 20),
				0,
				rng.randf_range(-20, 20)
			)
			print("___ \n Overlap: " + str(check_collision_area.has_overlapping_bodies()) + "\n Postion: " + str(check_collision_area.global_transform.origin))

		else: 
			temp_loop = false	
			
	
	if(not check_collision_area.has_overlapping_bodies()):
		game_master.add_lander(self, check_collision_area.global_transform.origin)

### Connected Signals
