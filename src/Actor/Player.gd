extends Actor

export var stomp_impulse = 1000.0
export var amount_of_jumps_possible = 1
var jumpcount = amount_of_jumps_possible

func _ready() -> void:
	#$arrow.hide()
	pass

func _on_EnemyDetector_area_entered(area: Area2D) -> void:
	_velocity = calculate_stomp_velocity(_velocity, stomp_impulse)
	

func _on_EnemyDetector_body_entered(body: PhysicsBody2D) -> void:
	pass
	#queue_free()

func _physics_process(delta: float) -> void:
	$ArrowOrigin.hide()
	
	var is_jump_interrupted = Input.is_action_just_released("jump") and _velocity.y < 0
	var direction = get_direction()
	
	var mouse_angle = null
	
	Engine.time_scale = 1
	
	if Input.is_action_pressed("mouse_button"):
		#Slows down time:
		Engine.time_scale = 0.25
		
		#arrow direction
		$ArrowOrigin.show()
		var mouse_pos = get_global_mouse_position()
		mouse_angle = $ArrowOrigin.global_position.angle_to(mouse_pos)
		$ArrowOrigin.look_at(mouse_pos)
		
	if Input.is_action_just_released("mouse_button") and mouse_angle != null:
		direction = Vector2(cos(mouse_angle), sin(mouse_angle))
	
	_velocity = calculate_move_velocity(_velocity, speed, direction, is_jump_interrupted)
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL)
	
	if Input.is_action_pressed("move_left"):
		get_node("player").set_flip_h( true )
	if Input.is_action_pressed("move_right"):
		get_node("player").set_flip_h( false )
		
	if is_on_floor():
		jumpcount = amount_of_jumps_possible
	
	if not is_on_floor():
		if _velocity.y < 300:
			$player.animation = "Jump_up"
		else:
			$player.animation = "Jump_down"
	elif Input.is_action_pressed("move_right") and Input.is_action_pressed("move_left"):
		$player.animation = "Idle"
	elif Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left"):
		$player.animation = "Running"
	else:
		$player.animation = "Idle"


func get_direction() -> Vector2:
	var x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y = 0.0
	if Input.is_action_just_pressed("jump") and jumpcount > 0:
		jumpcount -= 1
		if is_on_floor():
			y = -1.0
		#elif is_on_wall():
		#	y = -1.0
		#	x *= -3.0
		else:
			y = 1.0
	
	return Vector2(x, y)
	#return Vector2(
		#Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		#-1.0 if Input.is_action_just_pressed("jump") and is_on_floor() or is_on_wall() else 1.0
	#)


func calculate_move_velocity(
		linear_velocity: Vector2, 
		speed: Vector2, 
		direction: Vector2,
		is_jump_interrupted: bool
	) -> Vector2:
	var out = linear_velocity

	out.x = speed.x * direction.x
	
	out.y += gravity * get_physics_process_delta_time()
	if direction.y == -1.0:
		out.y = speed.y * direction.y
	if is_jump_interrupted:
		out.y = 0.0
	
	return out


func calculate_stomp_velocity(linear_velocity: Vector2, impulse: float) -> Vector2:
	var out = linear_velocity
	out.y = -impulse
	return out
