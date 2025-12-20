extends Resource
class_name UnitRes  # Optional, but helpful

@export var name: String
@export var description: String
@export var mesh: PackedScene
@export var cost: CostRes
@export var icon: CompressedTexture2D



const defualt_dmg_ref = "res://Scripts/Resources/damage/defualt_dmg.tres"
@export var damage: DamageRes = preload(defualt_dmg_ref)

#@export var abilities: Array[Ability]
