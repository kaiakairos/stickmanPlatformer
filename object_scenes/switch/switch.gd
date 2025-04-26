extends Node2D

@export var attachedObjects :Array[Node2D] = []

@onready var sprite = $Sprite

var playerHere :bool = false
var flipping :bool = false

func _ready() -> void:
	set_process(false)

func flip():
	if flipping:
		return
	flipping = true
	$CPUParticles2D.emitting = true
	sprite.flip_h = !sprite.flip_h
	
	await get_tree().create_timer(0.5).timeout
	
	for obj in attachedObjects:
		if obj.has_method("activate"):
			obj.activate()
		else:
			printerr("tried to activate non activatable object... check your @export array!")
	
	flipping = false
	
	
func _process(delta: float) -> void:
	
	if Global.camera.cameraFocused:
		return
	
	if Input.is_action_pressed("activate"):
		flip()


func _on_area_2d_body_entered(body: Node2D) -> void:
	playerHere = true
	set_process(true)

func _on_area_2d_body_exited(body: Node2D) -> void:
	playerHere = false
	
	#await get_tree().create_timer(1.0).timeout
	#if playerHere:
	#	return # player must have reentered the box...
	
	set_process(false)
