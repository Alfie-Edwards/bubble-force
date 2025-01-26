extends RigidBody2D

const DAMAGE_THRESHOLD = 100
const DAMAGE_MULTIPLIER = 0.01

@export var type: String
@export var wrapping_path: Vector2ArrayResource
@export var max_health: float = -1
@export var health: float = -1:
	set(new_value):
		if new_value <= 0:
			if _on_death:
				_on_death.call()
			health = 0
		else:
			health = new_value

@export var wrapping: float = 0:
	set(new_value):
		var delta = new_value - wrapping
		wrapping = new_value
		if is_node_ready():
			update_wrapping(delta)

var _collision_rects: Array[RectangleShape2D]
@export var _on_death: Callable


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Wrapping.points = wrapping_path.polygon
	for child in get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			_collision_rects.append(child.shape)

	update_wrapping(wrapping)


func update_wrapping(delta: float) -> void:
	$Wrapping.width = wrapping * 2
	for rect in _collision_rects:
		rect.size.x += delta * 2
		rect.size.y += delta * 2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if wrapping < 20:
		wrapping += delta
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _get_item_type() -> String:
	return type


func _integrate_forces(state : PhysicsDirectBodyState2D):
	for contact_index in state.get_contact_count():
		var object_hit := state.get_contact_collider_object(contact_index)
		if (is_instance_valid(object_hit)): # To fix a case where an object hits the player as player is deleted during level transition (intermission)
			var intensity = state.get_contact_impulse(contact_index).length()
			if object_hit.has_method("_get_item_type") and object_hit._get_item_type() == "dagger":
				intensity *= 2
			if intensity > DAMAGE_THRESHOLD:
				var damage = (intensity - DAMAGE_THRESHOLD) * DAMAGE_MULTIPLIER
				if damage > wrapping:
					health -= (damage - wrapping)
					wrapping = 0
				else:
					wrapping -= damage
				

func _get_configuration_warnings():
	var warnings: Array[String]
	if max_health < 0:
		warnings.append("`max_health` unset.")
	if health < 0:
		warnings.append("`health` unset.")
	if not wrapping_path:
		warnings.append("`wrapping_path` unset.")
	if not type:
		warnings.append("`type` unset.")
	return warnings
	
	
