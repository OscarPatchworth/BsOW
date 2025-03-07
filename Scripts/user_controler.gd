extends Node3D

@export var terrianHex: PackedScene
@export var cam: Camera3D
var mouse = Vector2()

#Get cam and world space init
var space_state
var mousepos 
#Get raycast points
var mouseRayStart 
var mouseRayEnd

const RAY_LENGTH = 100

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_released("left_click") and !raycatIslnad():
		spawnTerrian()




func spawnTerrian() -> void:
	var result = raycastPlaceable()
	if result: #if hits valid position
		var newHex = terrianHex.instantiate()
		owner.add_child(newHex)
		newHex.position = result["position"]				
func raycatIslnad() -> Dictionary:
	#Get cam and world space init
	initRaycastMousePos()
	#Raycast layer 2 (the island block layer)
	var query = PhysicsRayQueryParameters3D.create(mouseRayStart, mouseRayEnd, 2)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	return result
func raycastPlaceable() -> Dictionary:
	#Get cam and world space init
	initRaycastMousePos()
	#Raycast layer 1 (the placement layer)
	var query = PhysicsRayQueryParameters3D.create(mouseRayStart, mouseRayEnd, 1)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result	
func initRaycastMousePos() -> void:
	#Get cam and world space init
	space_state = get_world_3d().direct_space_state
	mousepos = get_viewport().get_mouse_position()
	#Get raycast points
	mouseRayStart = cam.project_ray_origin(mousepos)
	mouseRayEnd = mouseRayStart + cam.project_ray_normal(mousepos) * RAY_LENGTH
