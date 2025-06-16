extends Node3D

@onready var mesh = $MeshInstance3D
@export var validPlacementMaterial: Texture
@export var invalidPlacementMaterial: Texture
@onready var Ply := $"../UserControler"
@onready var rb = self.get_node("RigidBody3D")#rigidbody
@onready var A3D = self.get_node("Area3D")

@onready var bodies_overlapping: int

signal is_terrian_placeable(yn: bool)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	changeMaterial(validPlacementMaterial)
	is_terrian_placeable.emit(true)
	
	rb.set_contact_monitor(true)
	rb.set_use_continuous_collision_detection(true)
	rb.set_max_contacts_reported(5)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func check_placeable() -> void:
	if(bodies_overlapping == 0):
		changeMaterial(validPlacementMaterial)
		is_terrian_placeable.emit(true)	
	else:
		changeMaterial(invalidPlacementMaterial)
		is_terrian_placeable.emit(false)			

func changeMaterial(img: Texture) -> void:
	var material_one = mesh.get_surface_override_material(0)
	material_one.albedo_texture = img
	mesh.set_surface_override_material(0, material_one)


func _on_area_3d_body_entered(body: Node3D) -> void:
	bodies_overlapping += 1
	check_placeable()


func _on_area_3d_body_exited(body: Node3D) -> void:
	bodies_overlapping -= 1
	check_placeable()
