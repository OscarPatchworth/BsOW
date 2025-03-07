extends Node3D

@onready var mesh = $MeshInstance3D
@export var isCollidingMaterial: CompressedTexture2D
@export var IsOpenMaterial: CompressedTexture2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	mesh.set_surface_override_material(4, isCollidingMaterial)

func _on_area_3d_body_exited(body: Node3D) -> void:
	mesh.set_surface_override_material(4, IsOpenMaterial)
