@tool
class_name BasicOverworld
extends BaseOWSprite

enum Behavior {
	NOTHING,
	FACE_UP,
	FACE_DOWN,
	FACE_LEFT,
	FACE_RIGHT,
	ROTATE_CW,
	ROTATE_CCW,
	FACE_RANDOM
}

@export var frames: SpriteFrames
@export var behavior: Behavior :
	get:
		return behavior # TODOConverter40 Non existent get function 
	set(mod_value):
		behavior = mod_value
		_ready()

var state

func _ready():
	_set_frames(frames)
	if (behavior > 0 && behavior < 5):
		state = Face.new(behavior - 1)
	elif (behavior == 5):
		state = FaceRotate.new(true)
	elif (behavior == 6):
		state = FaceRotate.new(false)
	elif (behavior == 7):
		state = FaceRandom.new()
	else:
		state = WalkPath.back_and_forth(80, 80)
	state && state.initialize(self)

func _physics_process(delta):
	if (!self.locked && state && !state.done()):
		state.execute(self, delta)
		
func interact(p):
	lock()
	face(Angles.get_facing_for_angle(p.position - self.position))
	print("Hey!")

class Face:
	var direction
	
	func _init(direction):
		self.direction = direction
		
	func initialize(s: BaseOWSprite):
		s.face(self.direction)
	
	func execute(s, delta):
		pass
		
	func done():
		return true

class FaceRandom:
	extends Face
	
	var rng = RandomNumberGenerator.new()
	var timer
	
	func _init():
		super(0)
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
	
	func _init(cw):
		super(0)
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
	
	func _init(to,speed = 64):
		self.relative_final_position = to
		self.speed = speed
		
	func initialize(s: BaseOWSprite):
		self.final_position = s.position + self.relative_final_position
		s.run(Angles.get_facing_for_angle(self.relative_final_position))
	
	func execute(s: BaseOWSprite, delta: float):
		var direction_vector = (self.final_position - s.position)
		var facing = Angles.get_facing_for_angle(self.final_position - s.position)
		
		s.run(facing)
		s.move(direction_vector)
		
		var distance = (s.position - self.final_position).length()
		if distance < 5:
			s.position = self.final_position
			self.stopped = true
			s.stop_running()
		
	func done():
		return self.stopped

class WalkPath:
	extends Walk
	
	var waypoints
	var cursor = 0
	var loop
	
	func _init(waypoints,loop = true,speed = 64):
		super(waypoints[0], speed)
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
		super.execute(s, delta)
		if super.done():
			cursor += 1
			if (cursor < waypoints.size() || self.loop):
				cursor = cursor % waypoints.size()
				self.stopped = false
				self.relative_final_position = waypoints[cursor]
				super.initialize(s)
