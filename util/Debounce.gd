extends RefCounted

var timer: float
var current_timer: float

func _init(timer: float):
	self.timer = timer
	self.current_timer = timer

func complete() -> bool:
	return self.current_timer <= 0
	
func reset():
	self.current_timer = self.timer
	
func tick(delta: float):
	self.current_timer -= delta
	if self.current_timer < 0:
		self.current_timer = 0
	
func in_progress() -> bool:
	return self.current_timer > 0
