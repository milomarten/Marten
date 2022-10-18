extends KinematicBody2D

# Represents a face direction
enum Direction {
	NONE = -1,
	UP, 
	DOWN, 
	LEFT, 
	RIGHT
}

#Represents an action
enum OWState {
	IDLE,
	RUN
}

var speed = 128
var curDirection = Direction.UP
var curState = OWState.IDLE
var locked = false

var waitingTime = 0.1
var waitingForWhat = ""

onready var player = $Sprite as AnimatedSprite
onready var bounds = $BoundingBox as CollisionShape2D

func _ready():
	pass
		
func is_idle():
	return curState == OWState.IDLE

func is_running():
	return curState == OWState.RUN

func get_facing():
	return curDirection

func change_state(direction, state):
	var update = (self.curDirection != direction || 
		self.curState != state)
	self.curState = state
	self.curDirection = direction
	if (update) :
		configure_sprite_to_state()
		
func wait(for_what):
	waitingTime = 0.1
	waitingForWhat = for_what
	
func clear_wait():
	waitingForWhat = 0
	waitingForWhat = ""

func _physics_process(delta):
	if (!locked):
		if (waitingTime > 0):
			waitingTime -= delta
			if (waitingForWhat == "stop-running"):
				var direction = get_input_face_direction()
				if (direction != Direction.NONE):
					# You can break out of the debounce by hitting any direction key
					# Prevents issues with "lag" when changing directions mid-run
					change_state(direction, OWState.RUN)
					clear_wait()
		else:
			var direction = get_input_face_direction()
			if (waitingForWhat == "stop-running"):
				if (direction == Direction.NONE):
					# If direction is still none, stop running
					change_state(get_facing(), OWState.IDLE)
				else:
					# If direction is present, keep running
					change_state(direction, OWState.RUN)
				clear_wait()
			elif (waitingForWhat == "start-running"):
				if (direction != Direction.NONE):
					# Still holding the direction, so we can start running
					change_state(direction, OWState.RUN)
				clear_wait()
			elif (is_idle() && direction != Direction.NONE):
				if (curDirection != direction):
					# If changing direction, 
					# Face the new direction.
					# Kick off timer to see if you should
					# start running
					change_state(direction, OWState.IDLE)
					wait("start-running")
				else:
					# If you're already facing that way
					# We can start running immediately
					change_state(direction, OWState.RUN)
			elif (is_running()):
				if (direction == Direction.NONE):
					# If we're running and you stop
					# Wait a brief period.
					# We only do a full stop
					# If the time expires with no further presses
					wait("stop-running")
				else:
					# Keep running
					change_state(direction, OWState.RUN)
					# Translate
					move_and_slide(get_input_direction_vector().normalized() * speed)
	else:
		# When locked, default back to idle, facing in the
		# correct direction.
		change_state(get_facing(), OWState.IDLE)
		
func get_input_direction_vector():
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func get_input_face_direction():
	var point = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	if (point.x == 0 && point.y == 0):
		return Direction.NONE
	elif (point.y > point.x):
		if (point.y > -point.x):
			return Direction.UP
		else:
			return Direction.LEFT
	else:
		if (point.y < -point.x):
			return Direction.DOWN
		else:
			return Direction.RIGHT

const direction_names = ["up", "down", "right", "right"]
const state_names = ["default", "run"]
const hflip = [false, false, true, false]
const boundingbox = [
	[5, 17, 0, 0],
	[5, 17, 0, 0],
	[17, 5, 0, 9],
	[17, 5, 0, 9]
]

func configure_sprite_to_state():
	var anim = state_names[curState] + "-" + direction_names[curDirection]
	player.play(anim)
	player.flip_h = hflip[curDirection]
	
	var bb = boundingbox[curDirection]
	var shape = bounds.shape as RectangleShape2D;
	shape.extents.x = bb[0]
	shape.extents.y = bb[1]
	bounds.position.x = bb[2]
	bounds.position.y = bb[3]
