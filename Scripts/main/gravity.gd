# Class Name
extends Node # Extends

# Signals
signal reset_terrian_collision

# Constants
const GRAVITY_CONST = 6.6743E-11

# Static Vars
var calc_gravity = false
var num_Celestial_bodies = 0
var active_celestial_collider
var gravity_type
var gravity_affected

# Export Vars
@export var gravity_impulse_test = 15

# Dynamic Vars
var new_body: Node3D
var new_body_rb: RigidBody3D
var gravity_pull: Vector3
var celestial_bodies = [Terrian]

# OnReady Vars
@onready var data_node_ref = get_node("%DataNodeRefs")
@onready var data_settings = get_node("/" + data_node_ref.DATA_SETTINGS)
@onready var center = $"../../World_Objects/Box"

func _ready() -> void:
	
	gravity_type = data_settings.gravity_type
	gravity_affected = data_settings.gravity_affected

	if(gravity_type == 0): # simple gravity):
		print("Simple Gravity")
	elif(gravity_type == 1): # continuous gravity
		print("continuous Gravity")
	pass


func _process(delta: float) -> void:
	if num_Celestial_bodies < get_tree().get_nodes_in_group("terrian").size():
		celestial_bodies = get_tree().get_nodes_in_group("terrian")
		num_Celestial_bodies = celestial_bodies.size()

		newTerrianAdded()

		new_body_rb = celestial_bodies[celestial_bodies.size()-1].get_node("RigidBody3D")

	else:
		celestial_bodies = get_tree().get_nodes_in_group("terrian")


func _physics_process(delta: float) -> void:
	if(calc_gravity and new_body_rb != null):
		if (gravity_affected == data_settings.GravityAffectedTerrian.NEW):
			if !new_body_rb.is_sleeping():
				#print("Gravity Affects newbie")
				for i in range(celestial_bodies.size()):
					# calc_dir(self, target) -> V3
					var pull_dir = calc_direction(new_body, celestial_bodies[i])
					# calc_dist(self, target) -> float
					var dist = calc_distance(new_body, celestial_bodies[i])
					# apply_force(self, dir, dist)
					gravity_pull = (7000 / (dist**2)) * pull_dir

					match gravity_type:
						data_settings.GravityForceTypes.IMPULSE:
							new_body_rb.apply_central_impulse(gravity_pull)
							stop_calc_gravity()
						data_settings.GravityForceTypes.CONSTANT:
							new_body_rb.apply_central_force(gravity_pull)
							stop_calc_gravity()
						data_settings.GravityForceTypes.CONTINUOUS:
							new_body_rb.apply_force(gravity_pull)


					
					
		elif (gravity_affected == data_settings.GravityAffectedTerrian.ALL):
			#print("Gravity Affects ALL stars")
			
			for i in range(celestial_bodies.size()):
				if(not celestial_bodies[i].has_collided and not celestial_bodies[i].get_node("RigidBody3D").is_sleeping() ):
					for j in range(celestial_bodies.size()):
						# calc_dir(self, target) -> V3
						var pull_dir = calc_direction(celestial_bodies[i], celestial_bodies[j])
						# calc_dist(self, target) -> float
						var dist = calc_distance(celestial_bodies[i], celestial_bodies[j])
						# apply_force(self, dir, dist)
						gravity_pull = (7000 / (dist**2)) * pull_dir

						match gravity_type:
							data_settings.GravityForceTypes.IMPULSE:
								celestial_bodies[i].get_node("RigidBody3D").apply_central_impulse(gravity_pull)
								stop_calc_gravity()
							data_settings.GravityForceTypes.CONSTANT:
								celestial_bodies[i].get_node("RigidBody3D").apply_central_force(gravity_pull)
								stop_calc_gravity()
							data_settings.GravityForceTypes.CONTINUOUS:
								celestial_bodies[i].get_node("RigidBody3D").apply_force(gravity_pull)


func get_celestial_bodies() -> Array:
	celestial_bodies = get_tree().get_nodes_in_group("terrian")
	return celestial_bodies
	

func newTerrianAdded() -> void:
	if(get_celestial_bodies()):
		if(new_body != null):
			new_body.terrain_collision.disconnect(stop_calc_gravity)
			reset_terrian_collision.emit()

		new_body = celestial_bodies[celestial_bodies.size()-1]
		new_body_rb = new_body.get_node("RigidBody3D")
		calc_gravity = true
		new_body.terrain_collision.connect(stop_calc_gravity)
	else:
		pass


func calc_direction(i: Terrian, j: Terrian) -> Vector3:
	var pull_dir = (
			j.get_node("RigidBody3D").global_position - i.get_node("RigidBody3D").global_position
		).normalized()
	pull_dir.y = 0
	return pull_dir


func calc_distance(i: Terrian, j: Terrian) -> float:
	var i_celestial_pos = i.get_node("RigidBody3D").global_position
	var j_celestial_pos = j.get_node("RigidBody3D").global_position

	var dist = sqrt(
		(i_celestial_pos.x - j_celestial_pos.x)**2 + (i_celestial_pos.z - j_celestial_pos.z)**2
	)

	if dist < 0.6: dist = 0.6

	return dist

func stop_calc_gravity() -> void:
	calc_gravity = false
