extends Node2D

const MIN_SPILL_ANGLE : float = PI / 4
const SPILL_MULTIPLIER : float = 10


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Item._on_death = _on_death

func _on_death() -> void:
	print("Im a potion and I'm dead.")
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var damage_rate = (abs($"Item".transform.get_rotation()) - MIN_SPILL_ANGLE) / (PI - MIN_SPILL_ANGLE)
	if damage_rate > 0:
		$Item.health -= damage_rate * delta * SPILL_MULTIPLIER
