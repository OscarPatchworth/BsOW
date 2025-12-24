class_name PlayerControler
extends ActorControler


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass


# Called Whenever there is user input
func _input(event: InputEvent) -> void:
    if event.is_action_released("left_click"):
        print("Player L-Clicked")
    pass

