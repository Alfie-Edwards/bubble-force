extends CharacterBody2D


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var grab_ray: RayCast2D = $RayCast2D
@onready var hand: = $Hand
@onready var shoulder: = $Shoulder

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ARM_LENGTH = 15

var facing_right: bool = true


func _physics_process(delta: float) -> void:
	handle_movement(delta)

	set_animation()

	var picked_up: Node = maybe_pick_up()
	if picked_up != null:
		print("picked up ", picked_up.name)

	move_and_slide()


func _process(delta: float) -> void:
	# set arm rotation
	var mouse_pos: = get_viewport().get_mouse_position()

	grab_ray.target_position = (mouse_pos - grab_ray.global_position).normalized() * ARM_LENGTH + grab_ray.position

	shoulder.position = grab_ray.position
	hand.position = grab_ray.target_position


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
		facing_right = direction == 1
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func set_animation() -> void:
	# Play animations
	if !is_on_floor():
		animated_sprite.play("jump")
	elif velocity.x != 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

	# Draw direction
	animated_sprite.flip_h = not facing_right


func maybe_pick_up() -> Node:
	if Input.is_action_just_pressed("Pickup"):
		return grab_ray.get_collider()
	return null
