extends Resource
class_name RaceRes  # Optional, but helpful

@export var name: String
@export var description: String

@export var buildings: Array[BuildingRes]
@export var units: Array[UnitRes]
