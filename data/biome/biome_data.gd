# biome_data.gd
class_name BiomeData
extends Resource

## Authored definition of a biome. Landers display one of these.

@export var display_name: String
@export var mesh_material: Material
@export var icon: Texture2D
## Resources granted to the owner each upkeep phase.
@export var upkeep: EconData


#region Accessors
func get_display_name() -> String:
	return AbilitySystem.resolve_get(self, &"display_name", display_name)


func get_mesh_material() -> Material:
	return AbilitySystem.resolve_get(self, &"mesh_material", mesh_material)


func get_icon() -> Texture2D:
	return AbilitySystem.resolve_get(self, &"icon", icon)


func get_upkeep() -> EconData:
	return AbilitySystem.resolve_get(self, &"upkeep", upkeep)
#endregion
