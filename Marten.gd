class_name Player
extends BaseOWSprite

enum WaitingFor {
	NONE,
	START_RUNNING,
	STOP_RUNNING
}

const RUN_SPEED = 128
const SPIN_SPEED = 48

const MAX_SPIN = 5
var spinning = false
var spin_count = 0
var local_spin_count = 0
var dizzy = false

var waitingForWhat = WaitingFor.NONE
var debounce = load("res://util/Debounce.gd").new(0.05)

@onready var ray = $Interaction as RayCast2D
@onready var tail = $Tail as Area2D
@onready var tail_influence = $Tail/Influence as CollisionShape2D
		
func _wait(for_what: WaitingFor):
	debounce.reset()
	waitingForWhat = for_what
	
func _clear_wait():
	waitingForWhat = WaitingFor.NONE
	
func _start_spin():
	print("Start Spin")
	spinning = true
	super._set_speed(SPIN_SPEED)
	local_spin_count = 0
	tail_influence.disabled = false
	_configure_sprite_to_state()
	
func _stop_spin():
	print("Stop Spin")
	spinning = false
	super._set_speed(RUN_SPEED)
	local_spin_count = 0
	tail_influence.disabled = true
	_configure_sprite_to_state()
	
func _start_dizzy():
	print("Start Dizzy")
	dizzy = true
	_stop_spin()
	
func _stop_dizzy():
	print("Stop Dizzy")
	dizzy = false
	self.curDirection = Direction.DOWN
	_configure_sprite_to_state()

func _input(event):
	if event.is_action_pressed("spin") && !self.locked && !self.spinning && !self.dizzy:
		_start_spin()
	elif event.is_action_released("interact"):
		if !self.locked && !self.spinning && !self.dizzy:
			var hit = ray.get_collider()
			if hit != null && hit.has_method("interact"):
				hit.interact(self)

func _physics_process(delta):
	if self.locked:
		return
		
	if !Input.is_action_pressed("spin") && local_spin_count > 0:
		_stop_spin()
	
	debounce.tick(delta)
	
	if (debounce.in_progress()):
		if (waitingForWhat == WaitingFor.STOP_RUNNING):
			var direction = get_input_face_direction()
			if (direction != Direction.NONE):
				# You can break out of the debounce by hitting any direction key
				# Prevents issues with "lag" when changing directions mid-run
				run(direction)
				_clear_wait()
	else:
		var direction = get_input_face_direction()
		if (waitingForWhat == WaitingFor.STOP_RUNNING):
			if (direction == Direction.NONE):
				# If direction is still none, stop running
				stop_running()
			else:
				# If direction is present, keep running
				run(direction)
			_clear_wait()
		elif (waitingForWhat == WaitingFor.START_RUNNING):
			if (direction != Direction.NONE):
				# Still holding the direction, so we can start running
				run(direction)
			_clear_wait()
		elif (is_idle() && direction != Direction.NONE):
			if (curDirection != direction):
				# If changing direction, 
				# Face the new direction.
				# Kick unchecked timer to see if you should
				# start running
				face(direction)
				_wait(WaitingFor.START_RUNNING)
			else:
				# If you're already facing that way
				# We can start running immediately
				run(direction)
		elif (is_running()):
			if (direction == Direction.NONE):
				# If we're running and you stop
				# Wait a brief period.
				# We only do a full stop
				# If the time expires with no further presses
				_wait(WaitingFor.STOP_RUNNING)
			else:
				# Keep running
				run(direction)
				# Translate
				var input = Input.get_vector("left", "right", "up", "down")
				move(input)

func get_input_face_direction():
	if dizzy:
		return Direction.NONE
	var point = Input.get_vector("left", "right", "up", "down")
	if (point.x == 0 && point.y == 0):
		return Direction.NONE
	else:
		return get_facing_for_angle(point)

const ray_points = [
	[0, -16],
	[0, 16],
	[-16, 0],
	[16, 0]
]

func _configure_sprite_to_state():
	if spinning:
		sprite.play(&"spin")
		sprite.flip_h = false
	elif dizzy:
		sprite.play(&"dizzy")
		sprite.flip_h = false
	else:
		super._configure_sprite_to_state()
		ray.target_position = Vector2(ray_points[curDirection][0], ray_points[curDirection][1])

func _on_Sprite_animation_finished():
	if self.spinning:
		if spin_count < MAX_SPIN:
			local_spin_count += 1
			spin_count += 1
			if spin_count == MAX_SPIN:
				_start_dizzy()

func _on_Tail_body_entered(body: Node2D):
	if body.has_method("hit"):
		body.hit(self)

func _on_dizzy_timer_timeout():
	if !self.spinning:
		if spin_count > 0:
			spin_count -= 1
			if spin_count == 0 and self.dizzy:
				_stop_dizzy()


func _on_tail_body_exited(body: Node2D):
	if body.has_method("stop_hit"):
		body.stop_hit(self)
