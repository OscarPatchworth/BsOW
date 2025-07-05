extends Node3D

# signals
signal mouse_moved
signal biome_placed

# enums

enum PlayerStateMachine {INACTIVE, PLACING_TERRIAN}

# constants
const RAY_LENGTH = 100

# static variables

# export variables
@export var biome_hex: PackedScene
@export var cam: Camera3D
@export var check_terrain_paceable_sence: Node3D

# remaining regular variables
var mouse = Vector2()
#Get cam and world space init
var space_state
var mouse_pos 
#Get raycast points
var mouse_ray_start 
var mouse_ray_end
###
var is_terrian_placeable : bool
var player_state: PlayerStateMachine

# @onready variables
@onready var data_store = $"../../Env/DataStore"

func _ready() -> void:
	player_state = PlayerStateMachine.PLACING_TERRIAN
	is_terrian_placeable = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match player_state:
		PlayerStateMachine.INACTIVE:
			pass
		PlayerStateMachine.PLACING_TERRIAN:
			update_placing_terrian()
	

func _input(event: InputEvent) -> void:
	if event.is_action_released("left_click") and !raycat_island() and (is_terrian_placeable):
		spawn_terrian()
	elif event.is_action_pressed("shifting") and !raycat_island():
		check_terrain_paceable_sence.show()
	elif event.is_action_released("shifting"):
		check_terrain_paceable_sence.hide()

###################################################################################################
###	State Machine Funcs

### Switching to states

func switch_state_inactive() -> void:
	check_terrain_paceable_sence.hide()


func switch_state_placing_terrian() -> void:
	check_terrain_paceable_sence.hide()


### Update() states

func update_placing_terrian() -> void:
	if check_terrain_paceable_sence:
		move_to_mouse_pos(check_terrain_paceable_sence)


###################################################################################################
###	custom Funcs

func spawn_terrian() -> void:
	var result = raycast_placeable()
	if result: #if hits valid position
		var newHex = biome_hex.instantiate()
		owner.add_child(newHex)
		var newPos = result["position"]
		newPos.y =+ 0.1
		newHex.position = newPos
		newHex.updateBiome(data_store.next_biome)
		biome_placed.emit()		

		
func raycat_island() -> Dictionary:
	#Get cam and world space init
	init_raycast_mouse_pos()
	#Raycast layer 2 (the island block layer)
	var query = PhysicsRayQueryParameters3D.create(mouse_ray_start, mouse_ray_end, 2)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	return result


func raycast_placeable() -> Dictionary:
	#Get cam and world space init
	init_raycast_mouse_pos()
	#Raycast layer 1 (the placement layer)
	var query = PhysicsRayQueryParameters3D.create(mouse_ray_start, mouse_ray_end, 1)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result	


func init_raycast_mouse_pos() -> void:
	#Get cam and world space init
	space_state = get_world_3d().direct_space_state
	mouse_pos = get_viewport().get_mouse_position()
	#Get raycast points
	mouse_ray_start = cam.project_ray_origin(mouse_pos)
	mouse_ray_end = mouse_ray_start + cam.project_ray_normal(mouse_pos) * RAY_LENGTH


func move_to_mouse_pos(obj: Node3D) -> void:
	var result = raycast_placeable()
	if result and obj: #if hits valid position
		obj.position = result["position"]	
		#obj.position.y = obj.position.y +0.1
	mouse_moved.emit()


func _on_is_placeable_box_is_terrian_placeable(yn: bool) -> void:
	is_terrian_placeable = yn
