extends Node2D


var mouse_active: bool = true
var timeline_event: TimelineEvent


func _ready() -> void:
	SpeedBump.floor = $Floor
	Turn.inside = $Inside
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	mouse_active = true


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


func _process(delta: float) -> void:
	if timeline_event:
		timeline_event._tick(delta)


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
