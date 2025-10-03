extends Button

# signals
signal is_pressed(lander_ref)

# enums

# constants

# static variables
var lander_ref: Terrian
# @export variables

# remaining regular variables

# @onready variables

###################################################################################################
###	Methods

###	_built_in_methods()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass

func _pressed():
    is_pressed.emit(lander_ref)
    print("connected lander btn is_pressed emitted")

### Custom Methods



### Connected Signals