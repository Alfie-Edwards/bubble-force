extends Node2D


const RETURN_DURATION_SECONDS = 2

enum StaffState {IDLE, TAKEN, RETURNING}

var state: StaffState = StaffState.IDLE
var origin: Vector2 = Vector2(0, 0)


func _ready() -> void:
	origin = position


func try_take() -> bool:
	if state != StaffState.IDLE:
		return false
	state = StaffState.TAKEN
	visible = false
	return true


func release(from_pos: Vector2, from_rot: float) -> void:
	if state != StaffState.TAKEN:
		return
	state = StaffState.RETURNING
	visible = true
	position = from_pos
	rotation = from_rot
	z_index = 20
	move_back_to_origin()


func move_back_to_origin():
	var tween = get_tree().create_tween()

	tween.set_ease(Tween.EaseType.EASE_OUT)
	tween.set_trans(Tween.TransitionType.TRANS_EXPO)
	tween.set_parallel(true)
	tween.connect("finished", returned)

	tween.tween_property(self, "position", origin, RETURN_DURATION_SECONDS)
	tween.tween_property(self, "rotation", 0, RETURN_DURATION_SECONDS)


func returned():
	state = StaffState.IDLE
