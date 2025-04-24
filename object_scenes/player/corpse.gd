extends Node2D

var timeAlive :float = 0.0

func setVelocity(vel:Vector2):
	for child in get_children():
		child.linear_velocity = vel

func _process(delta: float) -> void:
	timeAlive += delta
	if timeAlive > 3.0:
		
		for child in get_children():
			if randi() % 2 == 0:
				child.show()
			else:
				child.hide()
	
	if timeAlive > 4.0:
		queue_free()
