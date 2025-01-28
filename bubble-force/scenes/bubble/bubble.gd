extends Sprite2D


@onready var collider: Area2D = $Area2D

const WRAP_AMOUNT = 0.33
const INITIAL_SPEED: float = 10
const BASE_LIFETIME_SECONDS = 3
const POP_DURATION = 0.2

const SCALE_RANGE = 0.4
const LIFETIME_RANGE = 0.4
const DIRECTION_RANGE = 0.4

var direction: float = 0
var time_started: int = 0
var popping: bool = false
var lifetime: float = 0


func _ready() -> void:
	self.modulate = Color(0.69, 0.96, 0.97, 0.75)


func initialise(pos: Vector2, velocity: Vector2) -> void:
	position = pos

	time_started = Time.get_ticks_msec()

	direction = velocity.angle()
	direction += randf_range(-DIRECTION_RANGE / 2,
							 DIRECTION_RANGE / 2)

	var size = randf_range(1 - (SCALE_RANGE / 2), 1 + (SCALE_RANGE / 2))
	scale *= Vector2(size, size)

	lifetime = BASE_LIFETIME_SECONDS * randf_range(1 - (LIFETIME_RANGE / 2),
												   1 + (LIFETIME_RANGE / 2))


func age() -> float:
	return (Time.get_ticks_msec() - time_started) / 1000.0


func current_speed() -> float:
	var age_fraction = age() / lifetime
	var eased = 1.0 if age_fraction == 1.0 else 1.0 - pow(2, -10 * age_fraction)
	return (1 - eased) * INITIAL_SPEED


func _physics_process(_delta: float) -> void:
	if collider.has_overlapping_bodies():
		try_wrap_item()
		pop()
	elif not popping:
		if age() < lifetime:
			var speed = current_speed()
			var velocity = Vector2(speed * cos(direction), speed * sin(direction))
			position += velocity
		elif age() < lifetime + POP_DURATION:
			pass
		else:
			pop()


func try_wrap_item() -> void:
	for node in collider.get_overlapping_bodies():
		if "wrapping" not in node:
			continue
		node.wrapping += WRAP_AMOUNT


func pop() -> void:
	popping = true
	queue_free()
