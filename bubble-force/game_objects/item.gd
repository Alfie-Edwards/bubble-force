extends RigidBody2D

@export var sprite: Texture
@export var collision_shapes: Array[RectangleShape2D]
@export var wrapping_path: Vector2ArrayResource
@export var max_health: int = -1
@export var health: int = -1
@export var wrapping: float = 0:
	set(new_value):
		if $Wrapping:
			$Wrapping.width = new_value * 2
		var delta = new_value - wrapping
		for rect in collision_shapes:
			rect.size.x += delta * 2
			rect.size.y += delta * 2
		wrapping = new_value


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.texture = sprite
	$Wrapping.points = wrapping_path.polygon
	for rect in collision_shapes:
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = rect
		add_child((collision_shape))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	


func _get_configuration_warnings():
	var warnings: Array[String]
	if max_health < 0:
		warnings.append("`max_health` unset.")
	if health < 0:
		warnings.append("`health` unset.")
	if not collision_shapes:
		warnings.append("`collision_shapes` unset.")
	if not wrapping_path:
		warnings.append("`wrapping_path` unset.")
	if not sprite:
		warnings.append("`sprite` unset.")
	return warnings
