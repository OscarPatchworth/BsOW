extends Node3D # Extends

# signals
signal is_terrian_placeable(yn: bool)

# enums

# constants

# static variables

# @export variables
@export var valid_placement_material: Texture
@export var invalid_placement_material: Texture

# remaining regular variables
var bodies_overlapping: int

# @onready variables
@onready var mesh = $MeshInstance3D
@onready var player_node := $"../UserControler"
@onready var rb = self.get_node("RigidBody3D")#rigidbody
@onready var a3D = self.get_node("Area3D")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	changeMaterial(valid_placement_material)
	is_terrian_placeable.emit(true)
	
	rb.set_contact_monitor(true)
	rb.set_use_continuous_collision_detection(true)
	rb.set_max_contacts_reported(5)

func check_placeable() -> void:
	if(bodies_overlapping == 0):
		changeMaterial(valid_placement_material)
		is_terrian_placeable.emit(true)	
	else:
		changeMaterial(invalid_placement_material)
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
