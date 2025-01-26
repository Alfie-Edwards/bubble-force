extends Node2D


@export var CRUISE_SPEED = 2
@export var ROAD_SPAWN_Z = 10
const ROAD_DEPTH = 1
const ONCOMING_MIN_DELAY = 100
const SPAWN_IDX: int = 4

var mouse_active: bool = true
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
@export var speed = 0
@export var road_turn_rate = 0

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
	move_child(last_road, SPAWN_IDX)
	first_road = last_road
	reset_timeline()


func _input(event):
	var t: int = Time.get_ticks_msec()

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


func _process(delta: float) -> void:
	var t: int = Time.get_ticks_msec()
	
	if timeline_events[timeline_event_idx]:
		if timeline_events[timeline_event_idx].ended:
			timeline_event_idx += 1
			if timeline_event_idx >= timeline_events.size():
				reset_timeline()
			timeline_events[timeline_event_idx]._begin(t)
		timeline_events[timeline_event_idx]._tick(delta, t)
	road_spawn_angle += road_turn_rate * delta

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
		move_child(last_road, SPAWN_IDX)
	
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
			move_child(new_oncoming, SPAWN_IDX)
			t_last_oncoming = t
	
	for child in get_children():
		if child.has_method("_update_perspective"):
			child._update_perspective(speed * delta, angle)
			var darkness = clampf(1 / child.z, 0, 0.5)
			child.modulate = Color(darkness, darkness, darkness, 1)
			

func next_event():
	pass


class TimelineEvent:
	var van: Node2D
	var t0: int
	var duration: int
	var ended: bool
	func _init(van: Node2D, duration: int) -> void:
		self.van = van
		self.duration = duration
		self.ended = false

	func _begin(t0: int) -> void:
		self.t0 = t0

	func _tick(delta: float, t: int) -> void:
		# print(t - t0)
		if (t - t0) > duration:
			_end()

	func _end() -> void:
		self.ended = true


class Stop extends TimelineEvent:
	func _init(van: Node2D) -> void:
		super(van, 2000)

	func _tick(delta: float, t: int) -> void:
		var progress = clamp((t - t0) / duration, 0, 1)
		van.speed = van.CRUISE_SPEED * (1 - progress)
		super(delta, t)


class Start extends TimelineEvent:
	func _init(van: Node2D) -> void:
		super(van, 2000)

	func _tick(delta: float, t: int) -> void:
		var progress = clamp((t - t0) / duration, 0, 1)
		van.speed = van.CRUISE_SPEED * progress
		super(delta, t)


class TurnRoad extends TimelineEvent:
	func _init(van: Node2D, turn_rate: float) -> void:
		super(van, int(1000 * van.ROAD_SPAWN_Z / van.CRUISE_SPEED))
		van.road_turn_rate = turn_rate


class TurnRoadLeft extends TurnRoad:
	func _init(van: Node2D) -> void:
		super(van, -0.15)


class TurnRoadRight extends TurnRoad:
	func _init(van: Node2D) -> void:
		super(van, 0.15)


class Pickup extends TimelineEvent:
	var items: Array[Node2D]
	var spawned: int
	func _init(van: Node2D, items: Array[Node2D]) -> void:
		self.items = items
		super(van, (items.size()) * 1000)

	func _tick(delta: float, t: int) -> void:
		var elapsed = (t - t0)
		var item = (elapsed / 1000)
		if item > -1 and item < items.size() and (delta * 1000) > (elapsed % 1000):
			print(item)
			items[item].transform = items[item].transform.translated(Vector2(576, -100))
			van.add_child(items[item])
		
		super(delta, t)


class Dropoff extends TimelineEvent:
	static var floor: Area2D
	var power: float

	func _init(van: Node2D) -> void:
		super(van, 2000)

	func _begin(t0: int) -> void:
		for child in van.get_children():
			if child.has_method("_get_item_type"):
				child.stops -= 1
				if child.stops == 0:
					child.queue_free()
		super(t0)


class SpeedBump extends TimelineEvent:
	static var floor: Area2D
	var power: float

	func _init(van: Node2D, power: float) -> void:
		self.power = power
		super(van, 2000)

	func _begin(t0: int) -> void:
		for body in floor.get_overlapping_bodies():
			if body is RigidBody2D:
				body.apply_impulse(Vector2(0, -self.power))
		super(t0)


class Turn extends TimelineEvent:
	static var inside: Area2D
	var power: float

	func _init(van: Node2D, power: float) -> void:
		self.power = power
		super(van, int(1000 * van.ROAD_SPAWN_Z / van.CRUISE_SPEED))
		van.road_turn_rate = 0

	func _tick(delta: float, t: int) -> void:
		for body in inside.get_overlapping_bodies():
			if body is RigidBody2D:
				body.apply_impulse(Vector2(self.power * delta, 0))
		super(delta, t)


class LeftTurn extends Turn:
	func _init(van: Node2D, power: float) -> void:
		super(van, -power)


class RightTurn extends Turn:
	pass


var tome = preload("res://game_objects/items/tome.tscn")
var tome2 = preload("res://game_objects/items/tome2.tscn")
var urn = preload("res://game_objects/items/urn.tscn")

var timeline_events: Array[TimelineEvent]
var timeline_event_idx : int = 0
func reset_timeline():
	timeline_events = [
		Stop.new(self),
		Pickup.new(self, [
			tome.instantiate(),
			tome2.instantiate(),
		]),
		Start.new(self),
		TurnRoadLeft.new(self),
		LeftTurn.new(self, 1000),
		SpeedBump.new(self, 200),
		Stop.new(self),
		Dropoff.new(self),
		Pickup.new(self, [
			tome.instantiate(),
			tome.instantiate(),
			tome.instantiate(),
			tome2.instantiate(),
			tome2.instantiate(),
		]),
	]
	timeline_event_idx = 0
