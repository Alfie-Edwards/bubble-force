extends Node2D


var mouse_active: bool = true


func _ready() -> void:
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
