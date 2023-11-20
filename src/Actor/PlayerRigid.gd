extends ActorRigid



export var acceleration = 10000
export var top_move_speed = 550
export var top_rolling_speed = 1500
export var top_jump_speed = 950
export var top_jump_time = 0.1
export var max_rolling_time = 2
export var stomp_impulse = 1000.0
export var amount_of_jumps_possible = 1
export var rolling_speed = 30000
var jumpcount = amount_of_jumps_possible
var rolling = false
var rolling_canceled = false
var cancel_time = 0
var max_cancel_time = 0.5
var collected_souls = 0
var dead = false

var on_wall_left = false
var on_wall_right = false
var grounded = false
var can_jump = false
var jump_time = 0
var rolling_time = 0

var starting_pos
var _velocity = Vector2()

const DIRECTION = {
	ZERO = Vector2(0, 0),
	LEFT = Vector2(-1, 0),
	RIGHT = Vector2(1, 0),
	UP = Vector2(0, -1),
	DOWN = Vector2(0, 1)
}

func _ready() -> void:
	starting_pos = global_position

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if dead:
		return
	var final_force = Vector2()
	
	_velocity = DIRECTION.ZERO
	
	apply_force(state)
	
	final_force = state.linear_velocity + (_velocity * acceleration)
	
	if not rolling: 
		final_force.x = clamp(final_force.x, -top_move_speed, top_move_speed)
		final_force.y = clamp(final_force.y, -top_jump_speed, top_jump_speed)
	else:
		final_force.x = clamp(final_force.x, -top_rolling_speed, top_rolling_speed)
		final_force.y = clamp(final_force.y, -top_rolling_speed * 1.2, top_rolling_speed * 1.2)
		
	state.linear_velocity = final_force

func apply_force(state):
	
	print(collected_souls)
	
	if rolling_canceled:
		if cancel_time > max_cancel_time:
			cancel_time = 0
			rolling_canceled = false
		
		cancel_time += state.step
		
	
	Engine.time_scale = 1
	$ArrowOrigin.hide()
	var mouse_pos = get_global_mouse_position()
	
	
	
	# Rolling ability, slingshot yourself with the mouse_button
	if Input.is_action_pressed("left_mouse_button") and not rolling_canceled and not rolling:
		
		if Input.is_action_pressed("right_mouse_button"):
			rolling_canceled = true
		
		#Slows down time:
		Engine.time_scale = 0.25
		
		#arrow direction
		$ArrowOrigin.show()
		$ArrowOrigin.look_at(mouse_pos)
	if Input.is_action_just_released("left_mouse_button") and not rolling_canceled and not rolling:
		
		rolling = true
		var direction = (get_global_mouse_position() - global_position).normalized()
		
		_velocity = Vector2()
		_velocity += direction
	
	if not rolling:
		$player.rotation = 0
		mode = RigidBody2D.MODE_CHARACTER
		get_node("BallCollision").set_deferred("disabled", true)
		get_node("RollingCollisionDetector").set_deferred("disabled", true)
		get_node("UpperbodyCollision").set_deferred("disabled", false)
		get_node("RayCollision").set_deferred("disabled", false)
		get_node("EnemyDetector").set_deferred("disabled", false)
		set_friction(0)
		set_bounce(0)
		
		if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
			_velocity = DIRECTION.ZERO
			# If the player is not using the roll ability stop moving
			linear_velocity.x = 0#lerp(linear_velocity.x, 0, 0.1)
	
			$player.animation = "Idle"
		elif Input.is_action_pressed("move_left") and not on_wall_left:
			get_node("player").set_flip_h( true )
			if grounded:
				$player.animation = "Running"
			_velocity += DIRECTION.LEFT
		elif Input.is_action_pressed("move_right") and not on_wall_right:
			get_node("player").set_flip_h( false )
			if grounded:
				$player.animation = "Running"
			_velocity += DIRECTION.RIGHT
		else:
			# If the player is not using the roll ability stop moving
			linear_velocity.x = 0#lerp(linear_velocity.x, 0, 0.1)
			$player.animation = "Idle"
		
			
		var just_jumped = false
		
		if Input.is_action_pressed("jump") and jump_time < top_jump_time and can_jump:
			_velocity += DIRECTION.UP
			jump_time += state.step
			just_jumped = true
		elif Input.is_action_just_released("jump"):
			can_jump = false
		
		if(grounded):
			just_jumped = false
			can_jump = true
			jump_time = 0
		
		# If not grounded and didn't jump
		if not grounded and not just_jumped:
			can_jump = false
		
		
		
		if not grounded:
			if linear_velocity.y < 300:
				$player.animation = "Jump_up"
			else:
				$player.animation = "Jump_down"
	else:
		# Using the roll ability!
		mode = RigidBody2D.MODE_RIGID
		get_node("BallCollision").set_deferred("disabled", false)
		get_node("RollingCollisionDetector").set_deferred("disabled", false)
		get_node("UpperbodyCollision").set_deferred("disabled", true)
		get_node("RayCollision").set_deferred("disabled", true)
		get_node("EnemyDetector").set_deferred("disabled", true)
		$player.animation = "Rolling"
		$player.rotate(linear_velocity.x * 0.001)
		set_friction(0.05)
		set_bounce(0.2)
		
		rolling_time += state.step
		
		#if stepify(linear_velocity.length(), 0.1) == 0:
		if linear_velocity.length() < 10.0 and rolling_time > 1: 
			rolling_time = 0
			rolling = false

func collect_soul(amount: int) -> bool:
	if amount > 0:
		collected_souls += amount
		return true
	else:
		return false

func _on_Area2D_body_entered(body: PhysicsBody2D) -> void:
	grounded = true


func _on_Area2D_body_exited(body: PhysicsBody2D) -> void:
	grounded = false

func _on_WallDetectorLeft_body_entered(body: PhysicsBody2D) -> void:
	on_wall_left = true


func _on_WallDetectorLeft_body_exited(body: PhysicsBody2D) -> void:
	on_wall_left = false


func _on_WallDetectorRight_body_entered(body: PhysicsBody2D) -> void:
	on_wall_right = true


func _on_WallDetectorRight_body_exited(body: PhysicsBody2D) -> void:
	on_wall_right = false


func _on_EnemyDetector_body_entered(body: PhysicsBody2D) -> void:
	if not rolling:
		die()


func _on_RollingCollisionDetector_body_entered(body: PhysicsBody2D) -> void:
	print("killed enemy")
	
func die():
	dead = true
	sleeping = true
	mode = RigidBody2D.MODE_STATIC
	$player.rotation = 0
	$player.animation = "Die"
	

func _on_player_animation_finished() -> void:
	if dead:
		$player.hide()
