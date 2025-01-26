extends Area2D


@export var radius: float = 0
@export var strength: float = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CollisionShape2D.shape.radius = radius


func explode() -> void:
	for body in get_overlapping_bodies():
		if body is RigidBody2D:
			var delta = body.global_position - global_position
			var dist = delta.length()
			if dist < radius:
				var power = strength * (radius - dist) / radius
				body.apply_impulse(delta.normalized() * power)
		
