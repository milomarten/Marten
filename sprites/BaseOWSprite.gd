class_name BaseOWSprite
extends CharacterBody2D

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

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var bounds: CollisionShape2D = $Bounds

@export var speed = 128
var curDirection = Direction.UP
var curState = OWState.IDLE
var locked = false

const animations = [
	[&"default-up", &"default-down", &"default-right", &"default-right"],
	[&"run-up", &"run-down", &"run-right", &"run-right"]
]
const hflip = [false, false, true, false]

func is_idle():
	return curState == OWState.IDLE

func is_running():
	return curState == OWState.RUN

func get_facing():
	return curDirection
	
func get_ow_position() -> Vector2:
	return bounds.global_position
	
func lock():
	locked = true
	
func lock_with(p):
	lock()
	p.lock()

func unlock():
	locked = false
	
func unlock_with(p):
	unlock()
	p.unlock()
	
func face(direction: Direction):
	_change_state(direction, OWState.IDLE)
	
func face_node(person: Node2D):
	face(get_facing_for_angle(person.position - self.position))
	
func run(direction: Direction):
	_change_state(direction, OWState.RUN)
	
func stop_running():
	_change_state(self.curDirection, OWState.IDLE)
	
func move(along: Vector2):
	set_velocity(along.normalized() * speed)
	move_and_slide()
	
func show_text(text, end_type = 0):
	var n = get_node("../../Textbox") as TextBox
	n.set_text(text)
	n.end_type = end_type
	n.show_box()
	await n.textbox_complete

func _set_speed(speed: float):
	self.speed = speed
	
func _set_frames(frames: SpriteFrames):
	self.sprite.frames = frames

func _change_state(direction: Direction, state: OWState):
	var update = (self.curDirection != direction || 
		self.curState != state)
	self.curState = state
	self.curDirection = direction
	if (update) :
		_configure_sprite_to_state()

func _configure_sprite_to_state():
	var name = animations[curState][curDirection]
	sprite.play(name)
	sprite.flip_h = hflip[curDirection]

func get_facing_for_angle(to: Vector2):
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
