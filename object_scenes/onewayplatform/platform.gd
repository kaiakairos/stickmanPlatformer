extends Line2D

func _ready() -> void:
	$StaticBody2D/CollisionPolygon2D.polygon = generateCollider()

func generateCollider() -> PackedVector2Array:
	var polygon : PackedVector2Array = []
	var inverse : PackedVector2Array = []
	
	
	for i in range(get_point_count()):
		
		var pointPos :Vector2= points[i] # get current point
		var prevPoint :Vector2= points[i]
		var nextPoint :Vector2= points[i]
		if i == 0: # no previous point
			prevPoint = points[i] + (points[i] - points[i + 1])
			nextPoint = points[i + 1]
		elif i == get_point_count() - 1: # no next point
			prevPoint = points[i-1]
			nextPoint = points[i] - (points[i-1] - points[i])
		else: # points? all good...
			prevPoint = points[i-1]
			nextPoint = points[i + 1]
		
		# now we have the positions of all points
		# get vector between points
		var path :Vector2= nextPoint - prevPoint
		var perp :float= path.orthogonal().angle()
		
		polygon.append( pointPos )
		inverse.append( pointPos + Vector2(-8,0).rotated( perp ) )
	
	inverse.reverse()
	polygon.append_array(inverse)
	
	return polygon
