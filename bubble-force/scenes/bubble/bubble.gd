extends Sprite2D


@onready var collider: Area2D = $Area2D

const INITIAL_SPEED: float = 10
const LIFETIME_SECONDS = 3
const POP_DURATION = 0.2

var direction: float = 0
var time_started: int = 0
var popping: bool = false


func initialise(pos: Vector2, velocity: Vector2) -> void:
	position = pos

	time_started = Time.get_ticks_msec()
	direction = velocity.angle()


func age() -> float:
	return (Time.get_ticks_msec() - time_started) / 1000.0


func current_speed() -> float:
	var age_fraction = age() / LIFETIME_SECONDS
	var eased = 1.0 if age_fraction == 1.0 else 1.0 - pow(2, -10 * age_fraction)
	return (1 - eased) * INITIAL_SPEED


func _physics_process(_delta: float) -> void:
	if collider.has_overlapping_bodies():
		pop()
	elif not popping:
		if age() < LIFETIME_SECONDS:
			var speed = current_speed()
			var velocity = Vector2(speed * cos(direction), speed * sin(direction))
			position += velocity
		elif age() < LIFETIME_SECONDS + POP_DURATION:
			pass
		else:
			pop()


func pop() -> void:
	popping = true
	queue_free()
