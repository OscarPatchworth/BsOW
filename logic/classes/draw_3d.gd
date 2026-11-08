# draw_3d.gd
# Source: https://github.com/androclus/Line-and-Sphere-Drawing
class_name Draw3D
extends Node

## Debug/feedback drawing helpers. `duration` is in seconds:
##   duration == 1 -> lasts only until the next physics frame
##   duration  > 0 -> freed after `duration` seconds
##   duration <= 0 -> stays until the caller frees the returned mesh

func line(pos1: Vector3, pos2: Vector3, color: Color = Color.WHITE_SMOKE, duration: float = 0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return await final_cleanup(mesh_instance, duration)

func point(pos: Vector3, radius: float = 0.05, color: Color = Color.WHITE_SMOKE, duration: float = 0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = sphere_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.position = pos

	sphere_mesh.radius = radius
	sphere_mesh.height = radius*2
	sphere_mesh.material = material

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return await final_cleanup(mesh_instance, duration)

func square(pos: Vector3, size: Vector2, color: Color = Color.WHITE_SMOKE, duration: float = 0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = box_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.position = pos

	box_mesh.size = Vector3(size.x, size.y, 1)
	box_mesh.material = material

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return await final_cleanup(mesh_instance, duration)


func circle(pos: Vector3, radius: float, color: Color = Color.WHITE_SMOKE, duration: float = 0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var circle_mesh := CylinderMesh.new()
	var material := ORMMaterial3D.new()

	mesh_instance.mesh = circle_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.position = pos

	circle_mesh.top_radius = radius
	circle_mesh.bottom_radius = radius
	circle_mesh.height = 1.5
	circle_mesh.material = material

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	return await final_cleanup(mesh_instance, duration)


func final_cleanup(mesh_instance: MeshInstance3D, duration: float) -> MeshInstance3D:
	get_tree().get_root().add_child(mesh_instance)
	if duration == 1:
		await get_tree().physics_frame
		mesh_instance.queue_free()
		return null
	elif duration > 0:
		await get_tree().create_timer(duration).timeout
		mesh_instance.queue_free()
		return null
	else:
		return mesh_instance
