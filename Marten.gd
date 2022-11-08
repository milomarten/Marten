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
	RUN,
	SPIN
}

const RUN_SPEED = 128
const SPIN_SPEED = 48
const MAX_SPIN = 5

var speed = RUN_SPEED
var curDirection = Direction.UP
var curState = OWState.IDLE
var locked = false

var spinning = false
var spin_count = 0
var local_spin_count = 0
var dizzy = false

var waitingTime = 0.1
var waitingForWhat = ""

@onready var player = $Sprite2D as AnimatedSprite2D
@onready var bounds = $Bounds as CollisionShape2D
@onready var sfx = $SFX as AudioStreamPlayer
@onready var ray = $Interaction as RayCast2D
@onready var tail = $Tail as Area2D
@onready var tail_influence = $Tail/Influence as CollisionShape2D

func _ready():
	pass
		
func is_idle():
	return curState == OWState.IDLE

func is_running():
	return curState == OWState.RUN

func get_facing():
	return curDirection

func _change_state(direction, state):
	var update = (self.curDirection != direction || 
		self.curState != state)
	self.curState = state
	self.curDirection = direction
	if (update) :
		configure_sprite_to_state()
		
func _wait(for_what):
	waitingTime = 0.05
	waitingForWhat = for_what
	
func _clear_wait():
	waitingForWhat = 0
	waitingForWhat = ""
	
func _start_spin():
	spinning = true
	speed = SPIN_SPEED
	local_spin_count = 0
	tail_influence.disabled = false
	configure_sprite_to_state()
	
func _stop_spin():
	spinning = false
	speed = RUN_SPEED
	tail_influence.disabled = true
	configure_sprite_to_state()
	
func _start_dizzy():
	dizzy = true
	_stop_spin()
	
func _stop_dizzy():
	dizzy = false
	self.curDirection = Direction.DOWN
	configure_sprite_to_state()

func _input(event):
	if event.is_action_pressed("ui_select") && !self.locked && !self.spinning && !self.dizzy:
		_start_spin()
	elif event.is_action_pressed("ui_accept") && !self.locked && !self.spinning && !self.dizzy:
		var hit = ray.get_collider()
		if hit != null && hit.has_method("interact"):
			hit.interact(self)
		else:
			print("Uh...?")

func _physics_process(delta):
	if !Input.is_action_pressed("ui_select") && local_spin_count > 0:
		_stop_spin()
		
	if (waitingTime > 0):
		waitingTime -= delta
		if (waitingForWhat == "stop-running"):
			var direction = get_input_face_direction()
			if (direction != Direction.NONE):
				# You can break out of the debounce by hitting any direction key
				# Prevents issues with "lag" when changing directions mid-run
				_change_state(direction, OWState.RUN)
				_clear_wait()
	else:
		var direction = get_input_face_direction()
		if (waitingForWhat == "stop-running"):
			if (direction == Direction.NONE):
				# If direction is still none, stop running
				_change_state(get_facing(), OWState.IDLE)
			else:
				# If direction is present, keep running
				_change_state(direction, OWState.RUN)
			_clear_wait()
		elif (waitingForWhat == "start-running"):
			if (direction != Direction.NONE):
				# Still holding the direction, so we can start running
				_change_state(direction, OWState.RUN)
			_clear_wait()
		elif (is_idle() && direction != Direction.NONE):
			if (curDirection != direction):
				# If changing direction, 
				# Face the new direction.
				# Kick unchecked timer to see if you should
				# start running
				_change_state(direction, OWState.IDLE)
				_wait("start-running")
			else:
				# If you're already facing that way
				# We can start running immediately
				_change_state(direction, OWState.RUN)
		elif (is_running()):
			if (direction == Direction.NONE):
				# If we're running and you stop
				# Wait a brief period.
				# We only do a full stop
				# If the time expires with no further presses
				_wait("stop-running")
			else:
				# Keep running
				_change_state(direction, OWState.RUN)
				# Translate
				var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
				set_velocity(input.normalized() * speed)
				move_and_slide()

func get_input_face_direction():
	if dizzy:
		return Direction.NONE
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

const animations = [
	[&"default-up", &"default-down", &"default-right", &"default-right"],
	[&"run-up", &"run-down", &"run-right", &"run-right"]
]
const hflip = [false, false, true, false]
const ray_points = [
	[0, -16],
	[0, 16],
	[-16, 0],
	[16, 0]
]

func configure_sprite_to_state():
	if spinning:
		player.play(&"spin")
		player.flip_h = false
		return
	elif dizzy:
		player.play(&"dizzy")
		player.flip_h = false
		return
	var name = animations[curState][curDirection]
	player.play(name)
	player.flip_h = hflip[curDirection]
	ray.target_position = Vector2(ray_points[curDirection][0], ray_points[curDirection][1])

func _on_Sprite_animation_finished():
	if self.spinning:
		if spin_count < MAX_SPIN:
			local_spin_count += 1
			spin_count += 1
			if spin_count == MAX_SPIN:
				_start_dizzy()

func _on_Tail_body_entered(body):
	if body != self:
		if body.has_method("hit"):
			var force = body.position - bounds.global_position
			body.hit(self, force)
		#elif body is TileMap:
			#todo: Determine nearest wall
			#var self_coords = to_global(self.bounds.position)
			#var tile_coords = body.local_to_map(self_coords)

func _on_dizzy_timer_timeout():
	if !self.spinning:
		if spin_count > 0:
			spin_count -= 1
			if spin_count == 0:
				_stop_dizzy()
