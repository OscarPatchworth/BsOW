# BuildingRes.gd
extends Resource
class_name BuildingRes  # Optional, but helpful

@export var name: String
@export var cost: CostRes 
@export var build_mesh: PackedScene
@export var build_icon: CompressedTexture2D
@export var unique_build = false
