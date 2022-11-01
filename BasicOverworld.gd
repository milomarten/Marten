tool
extends KinematicBody2D

enum Behavior {
	NOTHING,
	FACE_DOWN,
	FACE_UP,
	FACE_LEFT,
	FACE_RIGHT,
	ROTATE_CW,
	ROTATE_CCW,
	FACE_RANDOM
}

onready var sprite = $Sprite as AnimatedSprite

export(SpriteFrames) var frames
export(Behavior) var behavior setget set_behavior

var state

func _ready():
	sprite.frames = frames
	if (behavior > 0 && behavior < 5):
		state = Face.new(behavior - 1)
	elif (behavior == 5):
		state = FaceRotate.new(true)
	elif (behavior == 6):
		state = FaceRotate.new(false)
	elif (behavior == 7):
		state = FaceRandom.new()
	else:
		state = null
	state && state.initialize(self)

func _physics_process(delta):
	if (state && !state.done()):
		state.execute(self, delta)
		
func set_behavior(b):
	behavior = b
	_ready()
		
func interact(p):
	state = Face.new(Util.get_facing_for_angle(p.position - self.position))
	state.initialize(self)
	print("Hey!")
	
class Util:
	static func get_facing_for_angle(to):
		var theta = round(rad2deg(to.angle()))

		if (theta > 45):
			if (theta >= 135):
				return 2
			else:
				return 0
		else:
			if (theta >= -45):
				return 3
			elif (theta > -135):
				return 1
			else:
				return 2

class Face:
	var direction
	
	const anim_map = [
		["default-down", false], ["default-up", false], ["default-right", true], ["default-right", false]
	]
	
	func _init(direction):
		self.direction = direction
		
	func initialize(s):
		s.sprite.play(anim_map[direction][0])
		s.sprite.flip_h = anim_map[direction][1]
	
	func execute(s, delta):
		pass
		
	func done():
		return true

class FaceRandom:
	extends Face
	
	var rng = RandomNumberGenerator.new()
	var timer
	
	func _init().(0):
		rng.randomize()
		self.direction = rng.randi_range(0, 3)
		roll_timer()
	
	func execute(s, delta):
		timer -= delta
		if (timer <= 0):
			self.direction = rng.randi_range(0, 3)
			self.initialize(s)
			roll_timer()
		
	func done():
		return false
		
	func roll_timer():
		self.timer = rng.randf_range(1.0, 5.0)
		
class FaceRotate:
	extends Face
	
	const next_cw_face = [2, 3, 1, 0]
	const next_ccw_face = [3, 2, 0, 1]
	
	var next_face
	var timer
	
	func _init(cw).(0):
		self.next_face = next_cw_face if cw else next_ccw_face
		timer = 4.0
	
	func execute(s, delta):
		timer -= delta
		if (timer <= 0):
			self.direction = self.next_face[self.direction]
			self.initialize(s)
			timer = 4.0
		
	func done():
		return false

class Walk:
	var relative_final_position
	var final_position
	var speed
	var stopped = false
	
	const anim_map = [
		["run-down", false, "default-down"], 
		["run-up", false, "default-up"], 
		["run-right", true, "default-right"], 
		["run-right", false, "default-right"]
	]
	
	func _init(to, speed = 64):
		self.relative_final_position = to
		self.speed = speed
		
	func initialize(s):
		self.final_position = s.position + self.relative_final_position
		set_facing(s, Util.get_facing_for_angle(self.relative_final_position), false)
	
	func execute(s, delta):
		var direction_vector = (self.final_position - s.position).normalized() * speed
		var facing = Util.get_facing_for_angle(self.final_position - s.position)
		
		s.move_and_slide(direction_vector)
		
		var distance = (s.position - self.final_position).length()
		if distance < 5:
			s.position = self.final_position
			self.stopped = true
		set_facing(s, facing, self.stopped)
		
	func done():
		return self.stopped
		
	func set_facing(s, f, idle):
		print(f)
		s.sprite.play(anim_map[f][2 if idle else 0])
		s.sprite.flip_h = anim_map[f][1]

class WalkPath:
	extends Walk
	
	var waypoints
	var cursor = 0
	var loop
	
	func _init(waypoints, loop = true, speed = 64).(waypoints[0], speed):
		self.waypoints = waypoints
		self.loop = loop
		
	static func back_and_forth(x, y, speed=64):
		return WalkPath.new([Vector2(x, y), Vector2(-x, -y)], true, speed)
		
	static func square_loop(start, edge, speed=64):
		return WalkPath.new([
			Vector2(0, -edge),
			Vector2(edge, 0),
			Vector2(0, edge),
			Vector2(-edge, 0)
			], true, speed)
		
	func execute(s, delta):
		.execute(s, delta)
		if .done():
			cursor += 1
			if (cursor < waypoints.size() || self.loop):
				cursor = cursor % waypoints.size()
				self.stopped = false
				self.relative_final_position = waypoints[cursor]
				.initialize(s)
