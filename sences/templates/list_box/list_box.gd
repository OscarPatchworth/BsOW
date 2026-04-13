#list_box.gd
class_name ListBox
extends Control

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
	free_children(runtime_flow)
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


func _defualt_txt(obj) -> String:
	return str(obj)

### Connected Signals


## Calls
func set_objects(objs: Array, text_formatter: Callable = _defualt_txt):
	var formated_objs = objs.map(func(obj): return {"object" : obj, "text" : str(text_formatter.call(obj)) })
	list_items.assign(formated_objs)
	if list_items == []:
		pass
	else:
		make_list()
func get_objects() -> Array:
	return list_items



## Get/Set (er)s

### Connected Signals
