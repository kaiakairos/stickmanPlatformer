extends CharacterBody2D

@export var animationPlayer :AnimationPlayer
@export var sprite :Sprite2D

## Player Stats ##
var speed :float = 200.0
var accel :float = 1800.0
var gravity :float = 1000.0
var jumpPower :float = 330.0

var checkPoint :Vector2 = Vector2.ZERO

## Player Abilities ##
@export var canWallJump :bool = false
@export var canSlide :bool = false
@export var canChargeJump :bool = false


## yeah ##
var dir :int = 0
var jumpDelayTimer :float = 0.0

var coyoteDelayTimer :float = 0.0
var lastYOnFloor :float = 0.0

var wallSliding :bool = false

# if above 0, weakens horizontal acceleration
var accelDelayTimer :float = -10.0

var dead :bool = false

var slideOffFloorTime :float = 0.5

@onready var corpseScene = preload("uid://geucp7oenwe2")
@onready var camera = $PlayerCamera

var chargeTicks :float = 0.0
var chargeDir :Vector2 = Vector2.ZERO

var canCharge:bool = true

func _ready() -> void:
	checkPoint = global_position

func _process(delta: float) -> void:
	$SpeedLabel.text = str( int( velocity.x ) )

func movePlayer(delta):
	
	if camera.cameraFocused:
		return
	
	dir = int( Input.is_action_pressed("move_right") ) - int( Input.is_action_pressed("move_left") )
	
	if accelDelayTimer <= 0.0:
		velocity.x = move_toward(velocity.x,dir * speed,accel * delta)
	
	var wallCheck :int = checkForWall()
	var isOnFloor :bool = is_on_floor()
	
	velocity.y += gravity * delta # gravity
	if wallCheck != 0 and wallCheck == dir and !isOnFloor and canWallJump:
		if Input.is_action_pressed("crouch"):
			velocity.y = min(velocity.y,200.0)
		else:
			velocity.y = min(velocity.y,50.0)
		wallSliding = true
		
	else:
		wallSliding = false

	## jumping
	jumpDelayTimer -= delta
	if Input.is_action_just_pressed("jump"):
		jumpDelayTimer = 0.1
	
	if jumpDelayTimer > 0.0 and isOnFloor:
		jumpDelayTimer = -10.0
		velocity.y = -jumpPower
	
	# wall jump
	if wallCheck != 0 and jumpDelayTimer > 0.0 and dir != 0 and canWallJump:
		jumpDelayTimer = -10.0
		velocity = Vector2(260.0 * -wallCheck,-jumpPower )
		accelDelayTimer = 0.1666667
		coyoteDelayTimer = -10.0
	
	# coyote time
	if isOnFloor:
		coyoteDelayTimer = 0.1 # coyote time max
		lastYOnFloor = global_position.y
		accelDelayTimer = 0.0
		canCharge = true
	else:
		coyoteDelayTimer -= delta
		if Input.is_action_just_pressed("jump") and velocity.y > 0.5:
			if coyoteDelayTimer > 0.0:
				global_position.y = lastYOnFloor
				velocity.y = -jumpPower
				coyoteDelayTimer = -10.0
				jumpDelayTimer = -10.0
		accelDelayTimer -= delta
	
	move_and_slide()
	
	if accelDelayTimer <= 0.0:
		if dir != 0:
			sprite.flip_h = dir == -1
	else:
		sprite.flip_h = velocity.x < 0
	
	if isOnFloor:
		speed = move_toward(speed,200.0,200.0*delta)
	if dir == 1 and velocity.x < -1.0:
		speed = move_toward(speed,200.0,2000.0*delta)
	if dir == -1 and velocity.x > 1.0:
		speed = move_toward(speed,200.0,2000.0*delta)
	
	
func slide(delta):
	
	if camera.cameraFocused:
		return
	
	var isOnFloor :bool = is_on_floor()
	
	sprite.rotation = 0.0
	var iscol :bool= $slopeCastDetector.is_colliding()
	var onSlope :bool= false
	var slopDir :int = 0
	if iscol:
		var normal :Vector2 = $slopeCastDetector.get_collision_normal()
		if normal != Vector2.UP:
			onSlope = true
			
			sprite.rotation = normal.rotated((PI/2)).angle()
			
			if normal.angle() > -(PI/2):
				slopDir = 1
			else:
				slopDir = -1
			
	if onSlope:
		velocity.x = move_toward(velocity.x,slopDir * speed,400.0*delta)
		if velocity.x > 300.0 and dir == -1:
			dir = slopDir
		if velocity.x < -300.0 and dir == 1:
			dir = slopDir
		if dir == slopDir:
			speed += 200.0 * delta
		else:
			speed -= 200.0 * delta
	else:
		velocity.x = dir * speed
		speed = move_toward(speed,360.0,delta)
	
	velocity.y += gravity * delta
	
	coyoteDelayTimer -= delta
	slideOffFloorTime -= delta
	if isOnFloor:
		coyoteDelayTimer = 0.1
		slideOffFloorTime = 0.2
		lastYOnFloor = global_position.y
		canCharge = true
	
	move_and_slide()
	
	if abs(velocity.x) > 2.0:
		sprite.flip_h = velocity.x < 0
	
	if velocity.x > 10:
		dir = 1
	elif velocity.x < -10:
		dir = -1
	elif !onSlope:
		dir = 0

func charging(delta):
	
	canCharge = false
	
	velocity = lerp(velocity,Vector2.ZERO,0.2)
	move_and_slide()
	chargeTicks -= delta
	
	var dirt = Vector2.ZERO
	dirt.x = int( Input.is_action_pressed("move_right") ) - int( Input.is_action_pressed("move_left") )
	dirt.y = int( Input.is_action_pressed("look_down") ) - int( Input.is_action_pressed("look_up") )
	 
	chargeDir = dirt
	if chargeDir == Vector2.ZERO:
		chargeDir = Vector2(dir,0)

func charge(delta):
	chargeTicks -= delta
	velocity = chargeDir.normalized() * 600.0
	speed = max(200.0,abs(velocity.x) * 0.75)
	accelDelayTimer = 0.1
	move_and_slide()

func setStretch(newScale:Vector2) -> void:
	sprite.scale = newScale

func lerpStretch(newScale:Vector2,speed:float,delta:float) -> void:
	sprite.scale.x = move_toward(sprite.scale.x,newScale.x,speed * delta)
	sprite.scale.y = move_toward(sprite.scale.y,newScale.y,speed * delta)

func skidCheck() -> bool:
	if abs(velocity.x) > 1:
		return true
	return false

func checkForWall() -> int:
	# i might be stupid i flipped left and right on accident
	if $wallCasts/floorDistance.is_colliding():
		return 0 # say no wall if floor close
	
	if $wallCasts/right1.is_colliding() or $wallCasts/right2.is_colliding():
		return -1
	if $wallCasts/left1.is_colliding() or $wallCasts/left2.is_colliding():
		return 1
	return 0

func getSlope() -> float:
	if !$wallCasts/slopeDetector.is_colliding():
		return 0.0
	return snappedf($wallCasts/slopeDetector.get_collision_normal().rotated((PI/2)).angle(),0.001)


func _on_death_detector_body_entered(body: Node2D) -> void:
	if !dead:
		killPlayer()


func killPlayer():
	dead = true
	var ins = corpseScene.instantiate()
	ins.setVelocity((velocity * 1.5) + Vector2(0,-200))
	ins.global_position = global_position + Vector2(0,-8)
	get_parent().call_deferred("add_child",ins)
	sprite.hide()
	await get_tree().create_timer(2.5).timeout
	velocity = Vector2.ZERO
	global_position = checkPoint
	dead = false
	sprite.show()

func setCrouchShape(isCrouching:bool):
	if isCrouching:
		$CollisionShape2D.shape.size.y = 3.0
		$CollisionShape2D.position.y = 5.5
		
		$DeathDetector/CollisionShape2D.shape.size.y = 3.0
		$DeathDetector/CollisionShape2D.position.y = 4.5
		
	else:
		$CollisionShape2D.shape.size.y = 14.0
		$CollisionShape2D.position.y = 0.0
		
		$DeathDetector/CollisionShape2D.shape.size.y = 10.0
		$DeathDetector/CollisionShape2D.position.y = 0.0
		

func isCeilingCollider() -> bool:
	if $ceilingCollider.is_colliding():
		return true
	if $ceilingCollider2.is_colliding():
		return true
	return false

func checkCrouchGaps() -> int:
	if $wallCasts/right2.is_colliding():
		return -1
	if $wallCasts/left2.is_colliding():
		return 1
	return 0

func rotateOnSlope():
	if $slopeCastDetector.is_colliding():
		var normal :Vector2 = $slopeCastDetector.get_collision_normal()
		sprite.rotation = lerp_angle(sprite.rotation,normal.rotated((PI/2)).angle(),0.25)
