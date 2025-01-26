extends CharacterBody2D


# @onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedPlayer2
@onready var grab_ray: RayCast2D = $RayCast2D
@onready var arm: = $Arm
@onready var lol: = $Lol
@onready var hold_pos: = $HoldPos

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ARM_LENGTH = 100
const BUBBLE_COOLDOWN_SECONDS = 0.3

const PUSH_FORCE = 15.0
const MIN_PUSH_FORCE = 10.0

const THROW_RIGHT_VEL: = Vector2(200, -150)

const STAFF_ROT: float = 16.5
const STAFF_OFF_Y: float = 35

var facing_right: bool = true
var staff = null

var bubble_scene = preload("res://scenes/bubble/bubble.tscn")

var time_last_shot: float = -1

var held_item: Node = null
var held_item_owner: Node = null
var held_item_parent: Node = null


func holding_staff() -> bool:
	return staff != null


func _ready() -> void:
	animated_sprite.connect("animation_looped", anim_finished)
	animated_sprite.connect("animation_finished", anim_finished)
	print("to start, hold pos is ", hold_pos.position)


func set_ground_anim() -> void:
	if velocity.x != 0:
		animated_sprite.play("WalkSide")
	else:
		animated_sprite.play("IdleSide")


func anim_finished() -> void:
	if animated_sprite.animation == "JumpWindupSide":
		if !is_on_floor():
			animated_sprite.play("AirUpSide")
	elif animated_sprite.animation == "FallSide" and is_on_floor():
		set_ground_anim()


func get_vertical_bounds(rb: RigidBody2D):
	# var col_shapes = rb.find_children(".*", "CollisionShape2D")
	# print('have ', col_shapes.size())
	var current_top: float = INF
	var current_bottom: float = -INF
	# for cs in col_shapes:
	for cs in rb.get_children():
		if cs is not CollisionShape2D:
			continue
		# print('\tlooking at ', cs)
		var rect = cs.shape.get_rect()
		# print('\t\trect = ', rect)
		var top = min(rect.position.y, rect.end.y)
		var bottom = max(rect.position.y, rect.end.y)
		# print('\t\tthis shapes top is ', top)
		# print('\t\tthis shapes bottom is ', bottom)

		current_top = min(top, current_top)
		current_bottom = max(bottom, current_bottom)
		# print('\t\tcurrent top is ', current_top)
		# print('\t\tcurrent bottom is ', current_bottom)

	return { "top": current_top, "bottom": current_bottom }


func _physics_process(delta: float) -> void:
	handle_movement(delta)

	set_animation()

	if Input.is_action_just_pressed("Pickup"):
		if holding_staff():
			staff.release(grab_ray.global_position, arm.rotation)
			staff = null
		elif held_item != null:
			held_item.reparent(held_item_parent)
			held_item.set_owner(held_item_owner)

			held_item.freeze = false
			var impulse = THROW_RIGHT_VEL
			if not facing_right:
				impulse.x *= -1
			held_item.apply_central_impulse(impulse)
			held_item = null
			held_item_owner = null
		else:
			var picked_up: Node = maybe_pick_up()
			if picked_up != null:
				print("picked up ", picked_up.name, " (", picked_up.owner, ")")
				if picked_up.owner.name == "Staff":
					if picked_up.owner.try_take():
						staff = picked_up.owner
				elif held_item == null:
					var bounds = get_vertical_bounds(picked_up)


					held_item = picked_up
					held_item_parent = picked_up.get_parent()
					held_item_owner = picked_up.owner
					held_item.reparent(self)

					var hp = hold_pos.position
					if (not is_nan(bounds["bottom"])) and (not is_nan(bounds["top"])):
						var offset = ((bounds["bottom"] + bounds["top"]) / 2) - 20
						if abs(offset) < 800:
							hp.y -= offset

					held_item.position = hold_pos.position
					held_item.rotation = 0
					held_item.freeze = true

	var push_force = (PUSH_FORCE * velocity.length() / SPEED) + MIN_PUSH_FORCE
	if lol.is_colliding() and velocity != Vector2(0, 0):
		# print("lol: ", lol.get_collider(), " / ", lol.get_collision_normal())
		shunt(lol.get_collider(), velocity.normalized() * push_force)

	move_and_slide()

	# shunt items when you move into them
	# print("--------------")
	# print("speed ", velocity.length())
	# print("push force ", push_force)
	# print("colliding with ", get_slide_collision_count(), " items")
	# print("pos delta: ", get_position_delta())
	# print("real velocity: ", get_real_velocity())
	# print("last motion: ", get_last_motion())
	# print("vel: ", velocity)
	# print("wall normal: ", get_wall_normal())
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		# print(c, " -> ", c.get_collider())
		shunt(c.get_collider(), -c.get_normal() * push_force)
		# if c.get_collider() is RigidBody2D:
		# 	print("applying force to ", c.get_collider())
		# 	c.get_collider().apply_central_impulse(-c.get_normal() * push_force)
	# if lol.is_colliding() and velocity != Vector2(0, 0):
	# 	print("lol: ", lol.get_collider(), " / ", lol.get_collision_normal())
	# 	shunt(lol.get_collider(), velocity.normalized() * push_force)
	# else:
	# 	print("nope")


func shunt(collider, vector: Vector2) -> void:
	if collider is RigidBody2D:
		collider.apply_central_impulse(vector)


func _process(_delta: float) -> void:
	set_arm_rotation()

	arm.get_node("HeldStaff").visible = holding_staff()

	if holding_staff() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var now = Time.get_ticks_msec()
		if time_last_shot == -1 or now - time_last_shot > BUBBLE_COOLDOWN_SECONDS * 1000.0:
			time_last_shot = now
			shoot()


func hand_pos() -> Vector2:
	return grab_ray.position + grab_ray.target_position


func shoot():
	var bubble = bubble_scene.instantiate()
	bubble.initialise(position + (hand_pos() * scale), hand_pos() - grab_ray.position)
	get_parent().add_child(bubble)


func set_arm_rotation() -> void:
	# set arm rotation
	var mouse_pos: = get_viewport().get_mouse_position()

	grab_ray.target_position = (mouse_pos - grab_ray.global_position).normalized() * ARM_LENGTH

	var hp = hand_pos()
	var arm_pos: Vector2 = grab_ray.position + Vector2(grab_ray.scale.x / 2, grab_ray.scale.y / 2)


	var arm_length = arm.texture.get_height() * arm.scale.y

	var arm_distance_fraction = arm_length / ARM_LENGTH
	arm.position = arm_pos + (hp - arm_pos) * (1 - arm_distance_fraction)

	arm.flip_h = facing_right
	var staff_sprite = arm.get_node("HeldStaff")
	if facing_right:
		staff_sprite.rotation = deg_to_rad(180 - STAFF_ROT)
		staff_sprite.flip_h = true
		staff_sprite.position.x = -STAFF_OFF_Y
	else:
		staff_sprite.rotation = deg_to_rad(180 + STAFF_ROT)
		staff_sprite.flip_h = false
		staff_sprite.position.x = STAFF_OFF_Y

	# arm.position = (arm_pos + hp) / 2
	arm.rotation = atan2(hp.y - arm_pos.y, hp.x - arm_pos.x) - PI / 2


func handle_movement(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animated_sprite.play("JumpWindupSide")

	# Get the input direction (-1, 0, 1) and handle the movement/deceleration.
	var direction := Input.get_axis("Left", "Right")
	if direction:
		facing_right = direction == 1
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func set_animation() -> void:
	# # Play animations
	# if !is_on_floor():
	# 	animated_sprite.play("jump")
	# elif velocity.x != 0:
	# 	animated_sprite.play("run")
	# else:
	# 	animated_sprite.play("idle")
	# # Draw direction
	# animated_sprite.flip_h = not facing_right

	# # Play animations
	# if !is_on_floor():
	# 	pass
	# 	# animated_sprite.play("JumpWindupSide")
	# elif velocity.x != 0:
	# 	animated_sprite.play("WalkSide")
	# else:
	# 	animated_sprite.play("Idle")

	if is_on_floor() and not Input.is_action_just_pressed("Up") and animated_sprite.animation != "FallSide":
		set_ground_anim()
		# if velocity.x != 0:
		# 	animated_sprite.play("WalkSide")
		# else:
		# 	animated_sprite.play("Idle")
	elif !is_on_floor() and animated_sprite.animation == "AirUpSide" and velocity.y >= 0:
		animated_sprite.play("AirDownSide")
	elif animated_sprite.animation == "AirDownSide" and is_on_floor():
		animated_sprite.play("FallSide")

	# Draw direction
	animated_sprite.flip_h = facing_right


func maybe_pick_up() -> Node:
	if Input.is_action_just_pressed("Pickup"):
		return grab_ray.get_collider()
	return null
