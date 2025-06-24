extends Node3D

@export var biomeHex: PackedScene
#@export var checkPlacementObj: PackedScene
@export var cam: Camera3D
@export var checkPlaceable: Node3D
var mouse = Vector2()
@onready var dataStore = $"../../Env/DataStore"

signal biome_placed
signal mouse_moved

#Get cam and world space init
var space_state
var mousepos 
#Get raycast points
var mouseRayStart 
var mouseRayEnd
#
const RAY_LENGTH = 100
#
var isPlaceable : bool


func _ready() -> void:
	isPlaceable = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if checkPlaceable:
		moveToMousePos(checkPlaceable)
	

func _input(event: InputEvent) -> void:
	if event.is_action_released("left_click") and !raycatIslnad() and (isPlaceable):
		spawnTerrian()
	elif event.is_action_pressed("shifting") and !raycatIslnad():
		checkPlaceable.show()
	elif event.is_action_released("shifting"):
		checkPlaceable.hide()



#
func spawnTerrian() -> void:
	var result = raycastPlaceable()
	if result: #if hits valid position
		var newHex = biomeHex.instantiate()
		owner.add_child(newHex)
		var newPos = result["position"]
		newPos.y =+ 0.05
		newHex.position = newPos
		newHex.updateBiome(dataStore.nextbiome)
		emit_signal("biome_placed")		
#
#		
func raycatIslnad() -> Dictionary:
	#Get cam and world space init
	initRaycastMousePos()
	#Raycast layer 2 (the island block layer)
	var query = PhysicsRayQueryParameters3D.create(mouseRayStart, mouseRayEnd, 2)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	return result
#	
func raycastPlaceable() -> Dictionary:
	#Get cam and world space init
	initRaycastMousePos()
	#Raycast layer 1 (the placement layer)
	var query = PhysicsRayQueryParameters3D.create(mouseRayStart, mouseRayEnd, 1)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	return result	
#	
func initRaycastMousePos() -> void:
	#Get cam and world space init
	space_state = get_world_3d().direct_space_state
	mousepos = get_viewport().get_mouse_position()
	#Get raycast points
	mouseRayStart = cam.project_ray_origin(mousepos)
	mouseRayEnd = mouseRayStart + cam.project_ray_normal(mousepos) * RAY_LENGTH
#
func moveToMousePos(obj: Node3D) -> void:
	var result = raycastPlaceable()
	if result and obj: #if hits valid position
		obj.position = result["position"]	
		#obj.position.y = obj.position.y +0.1
	mouse_moved.emit()
	
func _on_is_placeable_box_is_terrian_placeable(yn: bool) -> void:
	isPlaceable = yn
