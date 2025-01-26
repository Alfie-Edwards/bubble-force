extends Node2D


const Z_SPEED: float = 1
const ROAD_SPAWN_Z = 10
const ROAD_DEPTH = 1
const ONCOMING_MIN_DELAY = 100

var mouse_active: bool = true
var timeline_event: TimelineEvent
var oncoming = preload("res://game_objects/effects/oncoming.tscn")
var road = preload("res://game_objects/effects/road.tscn")
var spr_tree1 = preload("res://assets/tree1.png")
var spr_tree2 = preload("res://assets/tree2.png")
var spr_tree3 = preload("res://assets/tree3.png")
var angle: float
var road_spawn_angle: float
var last_road: Polygon2D
var first_road: Polygon2D
var t_last_oncoming: int = 0

func _ready() -> void:
	randomize()
	SpeedBump.floor = $Floor
	Turn.inside = $Inside
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	mouse_active = true
	angle = 0
	
	last_road = road.instantiate()
	last_road.z = 1
	last_road.depth = ROAD_DEPTH
	last_road.angle_bottom = road_spawn_angle
	last_road.angle_top = road_spawn_angle
	add_child(last_road)
	move_child(last_road, 1)
	first_road = last_road


func _input(event):

	# (re)focusing the window
	if mouse_active and event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_active = false
		return

	if not mouse_active and event.is_action_pressed("Click") and \
	   Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
		mouse_active = true
		get_viewport().set_input_as_handled()  # stop the event from *also* registering as a regular shoot
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Y:
			if timeline_event:
				timeline_event._end()
			timeline_event = SpeedBump.new(200)
			timeline_event._begin()
		elif event.keycode == KEY_G:
			if timeline_event:
				timeline_event._end()
			timeline_event = LeftTurn.new(1000)
			timeline_event._begin()
		elif event.keycode == KEY_J:
			if timeline_event:
				timeline_event._end()
			timeline_event = RightTurn.new(1000)
			timeline_event._begin()
		elif event.keycode == KEY_H:
			if timeline_event:
				timeline_event._end()
				timeline_event = null
		elif event.keycode == KEY_L:
			var o = oncoming.instantiate()
			o.spawn_x = 0
			o.transform = Transform2D.IDENTITY.translated(Vector2(224, 577))
			add_child(o)


func _process(delta: float) -> void:
	var t: int = Time.get_ticks_msec()

	if timeline_event:
		timeline_event._tick(delta)
	road_spawn_angle += 0.1 * delta

	if (first_road.z + first_road.depth) <= 1:
		first_road = first_road.next_road

	var road_progress = (first_road.depth - first_road.z) / first_road.depth
	angle = first_road.angle_bottom + (first_road.angle_top - first_road.angle_bottom) * road_progress
	
	while (last_road.z + last_road.depth) <= ROAD_SPAWN_Z:
		var new_road = road.instantiate()
		new_road.z = (last_road.z + last_road.depth)
		new_road.depth = ROAD_DEPTH
		new_road.angle_bottom = last_road.angle_top
		new_road.angle_top = road_spawn_angle
		last_road.next_road = new_road
		last_road = new_road
		add_child(last_road)
		move_child(last_road, 1)
	
	if (t - t_last_oncoming) > ONCOMING_MIN_DELAY:
		if randf_range(0, 2) < delta:
			var new_oncoming = oncoming.instantiate()
			new_oncoming.z = ROAD_SPAWN_Z + ROAD_DEPTH
			new_oncoming.angle = road_spawn_angle
			var spr_idx = int(randf_range(0, 3))
			if spr_idx == 0:
				new_oncoming.texture = spr_tree1
			elif spr_idx == 1:
				new_oncoming.texture = spr_tree2
			elif spr_idx == 2:
				new_oncoming.texture = spr_tree3
			if randf_range(0, 1) < 0.5:
				new_oncoming.flip_h = true
			if randf_range(0, 1) < 0.5:
				new_oncoming.x = 576
			add_child(new_oncoming)
			move_child(new_oncoming, 1)
			t_last_oncoming = t
	
	for child in get_children():
		if child.has_method("_update_perspective"):
			child._update_perspective(Z_SPEED * delta, angle)
			


class TimelineEvent:
	func _begin() -> void:
		pass
	func _tick(delta: float) -> void:
		pass
	func _end() -> void:
		pass


class SpeedBump extends TimelineEvent:
	static var floor: Area2D
	var power: float

	func _init(power: float) -> void:
		self.power = power

	func _begin() -> void:
		for body in floor.get_overlapping_bodies():
			if body is RigidBody2D:
				body.apply_impulse(Vector2(0, -self.power))


class Turn extends TimelineEvent:
	static var inside: Area2D
	var power: float

	func _init(power: float) -> void:
		self.power = power

	func _tick(delta: float) -> void:
		for body in inside.get_overlapping_bodies():
			if body is RigidBody2D:
				body.apply_impulse(Vector2(self.power * delta, 0))


class LeftTurn extends Turn:
	func _init(power: float) -> void:
		super(-power)


class RightTurn extends Turn:
	pass
