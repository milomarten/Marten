extends Node

# Represents a face direction
enum Direction {
	NONE = -1,
	UP, 
	DOWN, 
	LEFT, 
	RIGHT
}

static func get_facing_for_angle(to: Vector2):
	var theta = round(rad_to_deg(to.angle()))
	if (theta > 45):
		if (theta >= 135):
			return Direction.LEFT
		else:
			return Direction.DOWN
	else:
		if (theta >= -45):
			return Direction.RIGHT
		elif (theta > -135):
			return Direction.UP
		else:
			return Direction.LEFT
