extends Node2D

@export var startOpen :bool = false

var openNow :bool = false

func _ready() -> void:
	if startOpen:
		$AnimationPlayer.play("open")
		$StaticBody2D/CollisionShape2D.call_deferred("set_disabled",true)

	
func activate():
	
	Global.camera.focusCamera( global_position )
	
	if openNow:
		$AnimationPlayer.play("close")
	else:
		$AnimationPlayer.play("open")
	
	$StaticBody2D/CollisionShape2D.call_deferred("set_disabled",!openNow)
	
	openNow = !openNow
	
	await get_tree().create_timer(1.0).timeout
	
	Global.camera.unfocusCamera()
