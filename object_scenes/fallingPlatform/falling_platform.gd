extends StaticBody2D

var time :float = 0.0
var encountered:bool = false

func _ready() -> void:
	set_process(false)
	Global.connect("enteredNewRoom",reset)

func _process(delta: float) -> void:
	time += delta
	
	if $visual.position.x <= 0:
		$visual.position.x = 2
	else:
		$visual.position.x = -2
	
	if time > 0.4:
		hide()
		set_process(false)
		$CollisionShape2D.call_deferred("set_disabled",true)
		await get_tree().create_timer(4.0).timeout
		if encountered:
			reset()
		
func reset():
	set_process(false)
	show()
	encountered = false
	$CollisionShape2D.call_deferred("set_disabled",false)
	$visual.position.x = 0

func _on_area_2d_body_entered(body: Node2D) -> void:
	if encountered:
		return
	set_process(true)
	encountered = true
	time = 0.0
