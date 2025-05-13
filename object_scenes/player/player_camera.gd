extends Camera2D

@onready var parent = get_parent()

var previousCamVec : Vector2i = Vector2i(-999,-999)

var cameraFocused :bool = false

func _ready() -> void:
	Global.camera = self

func _process(delta: float) -> void:
	
	if cameraFocused:
		return
	
	var camVec :Vector2i = Vector2i.ZERO
	camVec.x = int(parent.global_position.x) / 640
	camVec.y = int(parent.global_position.y) / 640
	
	if parent.global_position.x < 0:
		camVec.x -= 1
	if parent.global_position.y < 0:
		camVec.y -= 1
	
	if previousCamVec != camVec:
		previousCamVec = camVec
		sendSignal()
		get_tree().paused = true
		var tween :Tween= get_tree().create_tween().bind_node(self)
		tween.tween_property( self, "global_position", (Vector2(camVec) * 640) + Vector2(320,320), 0.4 ).set_trans(Tween.TRANS_LINEAR)
		await tween.finished
		get_tree().paused = false
		
		#parent.checkPoint = parent.global_position

func sendSignal():
	await get_tree().create_timer(0.4).timeout
	Global.emit_signal("enteredNewRoom")

func focusCamera(globPos):
	if globPos == null:
		unfocusCamera()
		return
	
	var camVec :Vector2i = Vector2i.ZERO
	camVec.x = int(globPos.x) / 640
	camVec.y = int(globPos.y) / 640
	
	if globPos.x < 0:
		camVec.x -= 1
	if globPos.y < 0:
		camVec.y -= 1
	
	global_position = (Vector2(camVec) * 640) + Vector2(320,320)
	cameraFocused = true

func unfocusCamera():
	
	var camVec :Vector2i = Vector2i.ZERO
	camVec.x = int(parent.global_position.x) / 640
	camVec.y = int(parent.global_position.y) / 640
	
	if parent.global_position.x < 0:
		camVec.x -= 1
	if parent.global_position.y < 0:
		camVec.y -= 1
	
	global_position = (Vector2(camVec) * 640) + Vector2(320,320)
	
	cameraFocused = false
