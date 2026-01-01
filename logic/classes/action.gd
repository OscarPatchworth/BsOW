class_name Action
extends Node

# signals

# enums
enum RequestType {
    MOVEMENT, 
    ATTACK,
    BUY
}

# constants

# static variables
var type: RequestType
var actor: Actor
var pos: Vector3
var target

# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods


### Get/Set (ers)
# Type
func get_type() -> RequestType:
    return self.type
func set_type(req_type: RequestType):
    self.type = req_type

# Actor
func get_actor() -> Actor:
    return self.actor
func set_actor(req_actor: Actor):
    self.actor = req_actor

# Pos
func get_pos() -> Vector3:
    return pos
func set_pos(req_pos: Vector3):
    self.pos = req_pos




