extends Node2D

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Water/WATER_SHADER.hide()
	Engine.time_scale = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_Water_body_entered(body: PhysicsBody2D) -> void:
	if body.get_name() == "Player_rigid":
		body.die()


func _on_CollisionShape2D_visibility_changed() -> void:
	if $Water.visible:
		$Water/WATER_SHADER.show()
	else:
		$Water/WATER_SHADER.hide()
