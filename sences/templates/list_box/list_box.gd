#list_box.gd
#class_name ClassName
extends Node

# signals
signal list_btn_pressed(thing)
# enums

# constants

# static variables

# @export variables

# remaining regular variables
var list_items: Array[Dictionary] # {object : Obj, text: ""}

var runtime_flow: Container

# @onready variables
@onready var template_btn: Button = self.find_child("TemplateButton")
@onready var template_flow = self.find_child("Container")

###################################################################################################
###	Methods
func _ready() -> void:
	runtime_flow = template_flow.duplicate()
	add_child(runtime_flow)
	template_flow.hide()


func free_children(parent: Node) -> void:
	for i in parent.get_children():
		i.queue_free()


func make_list():
	free_children(runtime_flow)
	for item in list_items:
		var new_btn = template_btn.duplicate()
		runtime_flow.add_child(new_btn)
		new_btn.text = item["text"]

		new_btn.pressed.connect(func(): fwd_btn_pressed(item["object"]))
		
	template_flow.hide()


func fwd_btn_pressed(thing):
	list_btn_pressed.emit(thing)


### Connected Signals


## Calls
func set_objects(objs: Array):
	list_items.assign(objs)
	if list_items == []:
		template_flow.show()
func get_objects() -> Array:
	return list_items



## Get/Set (er)s

### Connected Signals
