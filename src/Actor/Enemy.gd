extends "res://src/Actor/Actor.gd"

func _ready() -> void:
	_velocity.x = -speed.x


func _on_StompDetector_body_entered(body: PhysicsBody2D) -> void:
	if body.rolling == false:
		return 
	get_node("CollisionShape2D").disabled = true
	queue_free()


func _physics_process(delta: float) -> void:
	_velocity.y += gravity * delta
	
	if is_on_wall():
		_velocity.x *= -1.0 
	
	_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y