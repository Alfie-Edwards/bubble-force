extends Sprite2D


const origin: Vector2 = Vector2(576, 375)
const WIDTH: float = 1152
const HEIGHT: float = 648
@export var z: float
@export var angle: float
@export var x: float
var initial_transform: Transform2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initial_transform = Transform2D.IDENTITY.translated(Vector2(x, HEIGHT - texture.get_height() / 2))



func _update_perspective(progress: float, view_angle: float):
	z -= progress
	var rot_origin = Vector2(origin.x + tan(angle - view_angle) * (WIDTH / 2), origin.y)
	transform = initial_transform.translated(Vector2(x, 0) - rot_origin).scaled(Vector2(1/z, 1/z)).translated(rot_origin)
	if z <= 0:
		queue_free()
