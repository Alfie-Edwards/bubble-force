extends CharacterBody2D


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const PICKUP_RANGE = 10.0


func _physics_process(delta: float) -> void:
	handle_movement(delta)

	if Input.is_action_just_pressed("Pickup"):
		var picked_up: Node = pick_up()
		if picked_up != null:
			print("picked up ", picked_up.name)
		else:
			print("failed to pick anything up...")

	move_and_slide()


func handle_movement(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction (-1, 0, 1) and handle the movement/deceleration.
	var direction := Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Play animations
	if !is_on_floor():
		animated_sprite.play("jump")
	elif velocity.x != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

	# Draw direction
	if direction != 0:
		animated_sprite.flip_h = direction == -1


func pick_up() -> Node:
	return null
