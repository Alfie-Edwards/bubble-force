extends Polygon2D


const Z_SPEED: float = 1
const WIDTH: float = 1000
const BOTTOM: float = 648
const origin: Vector2 = Vector2(576, 375)
@export var next_road: Polygon2D
@export var z: float
@export var angle_top: float
@export var angle_bottom: float
@export var depth: float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _update_perspective(progress: float, view_angle: float):
	z -= progress
	z = max(0, z)
	var xo_top = origin.x + tan(angle_top - view_angle) * (WIDTH / 2)
	var xo_bottom = origin.x + tan(angle_bottom - view_angle) * (WIDTH / 2)
	var l = origin.x - WIDTH / 2
	var r = origin.x + WIDTH / 2
	
	var y_offset = BOTTOM - origin.y
	var top_z = z + depth
	polygon[0] = Vector2(xo_bottom + ((l - xo_bottom) / z), origin.y + (y_offset / z))
	polygon[1] = Vector2(xo_bottom + ((r - xo_bottom) / z), origin.y + (y_offset / z))
	polygon[2] = Vector2(xo_top + ((r - xo_top) / top_z), origin.y + (y_offset / top_z))
	polygon[3] = Vector2(xo_top + ((l - xo_top) / top_z), origin.y + (y_offset / top_z))
	
	if z < 0:
		queue_free()
	
