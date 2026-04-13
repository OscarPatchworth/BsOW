#movement_panel.gd
#class_name ClassName
extends Node

# signals

# enums

# constants

# static variables
var lander_manager: GameManager

# @export variables

# remaining regular variables
var from_lander: Lander
var to_lander: Lander

# @onready variables
@onready var from_panel: Panel = self.find_child("FromPanel")
@onready var to_panel: Panel = self.find_child("ToPanel")
@onready var arrow_rtl: RichTextLabel = self.find_child("ArrowRTL")

###################################################################################################
###	Methods
func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


### Connected Signals


## Calls
func bind_lander_manager(lm: GameManager):
	lander_manager = lm


func setup_display():
	if(to_lander == null or from_lander == null):
		print("Movement Panel | Err | setup_display() called without set landers ")
		return
	else:
		from_panel.find_child("Label").text = from_lander.get_biome().name
		to_panel.find_child("Label").text = to_lander.get_biome().name


## Get/Set (er)s
func get_to_lander() -> Lander:
	return to_lander
func set_to_lander(lnd: Lander):
	to_lander = lnd


func get_from_lander() -> Lander:
	return from_lander
func set_from_lander(lnd: Lander):
	from_lander = lnd


### Connected Signals
