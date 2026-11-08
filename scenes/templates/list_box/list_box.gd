# list_box.gd
class_name ListBox
extends Control

## A list of buttons built from arbitrary objects. Pressing a button emits the object it represents.
## The scene holds a hidden "TemplateButton" inside "Container" that each button is duplicated from.

signal item_pressed(item: Variant)

## Each entry: { "item": Variant, "text": String, "icon": Texture2D }
var _entries: Array[Dictionary] = []
var _runtime_container: Container

@onready var _template_button: Button = find_child("TemplateButton")
@onready var _template_container: Container = find_child("Container")


func _ready() -> void:
	_runtime_container = _template_container.duplicate()
	add_child(_runtime_container)
	_free_children(_runtime_container)
	_template_container.hide()


#region Public API
## Rebuilds the list. `text_for` / `icon_for` turn an item into its label / icon.
func set_items(items: Array, text_for: Callable = _default_text, icon_for: Callable = _default_icon) -> void:
	_entries.assign(items.map(func(item: Variant) -> Dictionary:
		return {"item": item, "text": str(text_for.call(item)), "icon": icon_for.call(item)}))
	if items.is_empty():
		clear()
	else:
		_rebuild()


func get_items() -> Array:
	return _entries.map(func(entry: Dictionary) -> Variant: return entry["item"])


## The buttons, in item order. Waits a frame so freshly built buttons exist.
func get_buttons() -> Array[Node]:
	await get_tree().process_frame
	return _runtime_container.get_children()


func clear() -> void:
	_free_children(_runtime_container)
#endregion


#region Private
func _rebuild() -> void:
	_free_children(_runtime_container)
	for entry in _entries:
		var button := _template_button.duplicate() as Button
		_runtime_container.add_child(button)
		button.text = entry["text"]
		button.icon = entry["icon"]
		var item: Variant = entry["item"]
		button.pressed.connect(func() -> void: item_pressed.emit(item))


func _free_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func _default_text(item: Variant) -> String:
	return str(item)


func _default_icon(_item: Variant) -> Texture2D:
	return null
#endregion
