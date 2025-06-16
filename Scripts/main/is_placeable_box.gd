extends Node3D

@onready var mesh = $MeshInstance3D
@export var validPlacementMaterial: Texture
@export var invalidPlacementMaterial: Texture
@onready var Ply := $"../UserControler"
@onready var rb = self.get_node("RigidBody3D")#rigidbody

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	changeMaterial(invalidPlacementMaterial)
	rb.set_contact_monitor(true)
	#rb.set_use_continuous_collision_detection(true)
	rb.set_max_contacts_reported(5)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(rb.get_contact_count() != 0):
		print(rb.get_contact_count())
	pass
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	#print(rb.get_contact_count())
	changeMaterial(invalidPlacementMaterial)
	Ply.updateIsPlaceable(false)
	

func _on_area_3d_body_exited(body: Node3D) -> void:
	changeMaterial(validPlacementMaterial)
	Ply.updateIsPlaceable(true)
	
func changeMaterial(img: Texture) -> void:
	var material_one = mesh.get_surface_override_material(0)
	material_one.albedo_texture = img
	mesh.set_surface_override_material(0, material_one)


func _on_is_placeable(emitter: Variant) -> void:
	pass # Replace with function body.
