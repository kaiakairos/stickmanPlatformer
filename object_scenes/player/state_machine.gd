extends Node

var state = null : set = set_state
var previous_state = null
var states = {}

@onready var parent = get_parent()

@export var label :Label

func _ready() -> void:
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("skid")
	add_state("fall")
	add_state("wallSlide")
	add_state("crouch")
	add_state("slide")
	add_state("dead")
	
	set_state(states.idle)

func _state_logic(delta):
	
	label.text =  states.keys()[state]
	
	match state:
		states.idle:
			parent.movePlayer(delta)
			parent.lerpStretch(Vector2(1,1),3.0,delta)
		states.run:
			parent.movePlayer(delta)
			parent.lerpStretch(Vector2(1,1),3.0,delta)
			parent.rotateOnSlope()
			parent.animationPlayer.speed_scale = max(1.0,abs(parent.velocity.x)/200.0)
		states.skid:
			parent.movePlayer(delta)
			parent.lerpStretch(Vector2(1,1),3.0,delta)
		states.jump:
			parent.movePlayer(delta)
			parent.lerpStretch(Vector2(1,1),3.0,delta)
			parent.coyoteDelayTimer = -10.0
		states.fall:
			parent.movePlayer(delta)
			parent.lerpStretch(Vector2(0.8,1.2),1.0,delta)
		states.wallSlide:
			parent.movePlayer(delta)
			parent.lerpStretch(Vector2(1.0,1.0),1.0,delta)
		states.crouch:
			parent.lerpStretch(Vector2(1.0,1.0),1.0,delta)
		states.slide:
			parent.slide(delta)
			parent.lerpStretch(Vector2(1.0,1.0),1.0,delta)

func _get_transition(delta):
	
	if parent.dead:
		return states.dead
	
	match state:
		states.idle:

			if parent.dir != 0:
				return states.run
			
			if parent.velocity.y < -1:
				return states.jump
			if parent.velocity.y > 1:
				return states.fall
			
			if Input.is_action_pressed("crouch"):
				return states.crouch
			
		states.run:
			
			
			if parent.dir == 0:
				if abs(parent.velocity.x) > 1:
					return states.skid
				else:
					return states.idle
			
			if parent.velocity.y < -1:
				return states.jump
			if parent.velocity.y > 1:
				return states.fall
			
			if Input.is_action_pressed("crouch"):
				var dir = int( Input.is_action_pressed("move_right") ) - int( Input.is_action_pressed("move_left") )
				if abs(parent.velocity.x) > 2.0 or parent.checkCrouchGaps() != dir * -1:
					return states.slide
				else:
					return states.crouch
		
		states.skid:
			
			if parent.velocity.y < -1:
				return states.jump
			if parent.velocity.y > 1:
				return states.fall
			
			if parent.dir != 0:
				return states.run
			elif abs(parent.velocity.x) < 1:
				return states.idle
		
		states.jump:
			if parent.is_on_floor():
				if parent.dir == 0:
					return states.idle
				else:
					return states.run
			
			if parent.velocity.y > 1:
				return states.fall
			
			if parent.wallSliding:
				return states.wallSlide
		
		states.fall:
			if parent.is_on_floor():
				if parent.dir == 0:
					return states.idle
				else:
					return states.run
			
			if parent.velocity.y < -1:
				return states.jump
			
			if parent.wallSliding:
				return states.wallSlide
		states.wallSlide:
			if !parent.wallSliding:
				if parent.is_on_floor():
					return states.idle
				else:
					return states.fall
		states.dead:
			if !parent.dead:
				return states.idle
		states.crouch:
			
			if !parent.is_on_floor():
				return states.fall
			
			
			if !parent.isCeilingCollider():
				if !Input.is_action_pressed("crouch"):
					return states.idle
			var dir = int( Input.is_action_pressed("move_right") ) - int( Input.is_action_pressed("move_left") )
			if dir != 0:
				if !parent.isCeilingCollider():
					if parent.checkCrouchGaps() == dir :
						return null
				parent.dir = dir
				return states.slide
			
		states.slide:
			
			if !parent.isCeilingCollider():
				if !Input.is_action_pressed("crouch"):
					return states.run
				if Input.is_action_just_pressed("jump") and parent.coyoteDelayTimer > 0.0:
					parent.velocity.y = -parent.jumpPower
					return states.jump
				if parent.slideOffFloorTime < 0.0:
					return states.fall
			if parent.dir == 0:
				return states.crouch
			
			
	return null

func _enter_state(new_state,old_state):
	match new_state:
		states.idle:
			parent.speed = 200.0
			if old_state == states.crouch:
				parent.animationPlayer.play("crouchToIdle")
				return
			parent.animationPlayer.play("idle")
		states.run:
			parent.animationPlayer.play("run")
		states.skid:
			parent.animationPlayer.play("skid")
		states.jump:
			parent.animationPlayer.play("jump")
			if old_state != states.fall:
				parent.setStretch(Vector2(0.6,1.4))
		states.fall:
			if old_state == states.jump:
				parent.animationPlayer.play("fall")
			else:
				parent.animationPlayer.play("fallInstant")
		states.wallSlide:
			parent.animationPlayer.play("wallSlide")
			parent.speed = 200.0
		states.crouch:
			parent.speed = 200.0
			parent.setCrouchShape(true)
			if old_state == states.slide:
				parent.animationPlayer.play("slidetocrouch")
				return
			parent.animationPlayer.play("crouch")
		states.slide:
			parent.setStretch(Vector2(1.2,0.6))
			if parent.speed < 360.0:
				parent.speed = 360.0
			parent.setCrouchShape(true)
			parent.animationPlayer.play("slide")
			parent.slideOffFloorTime = 0.5
			parent.floor_snap_length = 12.0
			parent.floor_constant_speed = false
			if parent.dir == 0:
				if parent.sprite.flip_h:
					parent.dir = -1
				else:
					parent.dir = 1

func _exit_state(old_state, new_state):
	match old_state:
		states.run:
			parent.sprite.rotation = 0.0
			parent.animationPlayer.speed_scale = 1.0
		states.fall:
			if new_state == states.wallSlide:
				return
			parent.setStretch(Vector2(1.2,0.6))
		states.crouch:
			if new_state != states.slide:
				parent.setCrouchShape(false)
		states.slide:
			parent.setCrouchShape(false)
			parent.floor_max_angle = deg_to_rad(45.0)
			parent.floor_snap_length = 4.0
			parent.floor_constant_speed = true
			parent.sprite.rotation = 0.0

#### dont edit things below ####

func _process(delta):
	if state != null:
		_state_logic(delta)
		var transition = _get_transition(delta)
		if transition != null:
			set_state(transition)

func set_state(new_state):
	previous_state = state
	state = new_state
	
	if previous_state != null:
		_exit_state(previous_state,new_state)
	
	if new_state != null:
		_enter_state(new_state,previous_state)

func add_state(state_name):
	states[state_name] = states.size()
