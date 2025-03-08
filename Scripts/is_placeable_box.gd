extends Node3D

@onready var mesh = $MeshInstance3D
@export var isCollidingMaterial: Texture
@export var isOpenMaterial: Texture
@onready var Ply := $"../UserControler"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	changeMaterial(isOpenMaterial)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	changeMaterial(isCollidingMaterial)
	Ply.updateIsPlaceable(false)
	

func _on_area_3d_body_exited(body: Node3D) -> void:
	changeMaterial(isOpenMaterial)
	Ply.updateIsPlaceable(true)
	
func changeMaterial(img: Texture) -> void:
	var material_one = mesh.get_surface_override_material(0)
	material_one.albedo_texture = img
	mesh.set_surface_override_material(0, material_one)


func _on_is_placeable(emitter: Variant) -> void:
	pass # Replace with function body.
