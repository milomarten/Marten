class_name TextBox
extends CanvasLayer

signal textbox_complete

enum EndType {
	NORMAL,
	NONE,
	QUESTION
}

@onready var label: RichTextLabel = $Box/Foreground/Label
@onready var pointer: TextureRect = $Box/Foreground/Pointer

@onready var animation: AnimationPlayer = $AnimationPlayer

var text: Array[String] = []
var end_type := EndType.QUESTION
var focused := false

var current_block := 0

# This forces the button to be pressed AND released for a trigger.
var input_speedbump := false

func set_text(text):
	if text is String:
		self.text = [text]
	else:
		self.text = text

func show_box():
	self.visible = true
	self.focused = true
	self.current_block = 0
	update_pointer()
	update_text()
	animation.play(&"Arrow Bounce")
	
func hide_box():
	self.visible = false
	self.focused = false
	animation.stop()
	
func update_text():
	label.text = self.text[self.current_block]

func update_pointer():
	if is_at_end():
		match self.end_type:
			EndType.NONE:
				pointer.visible = false
			EndType.QUESTION:
				pointer.visible = true
				pointer.texture = preload("res://ui/question.png")
			_:
				pointer.visible = true
				pointer.texture = preload("res://ui/enter.png")
	else:
		pointer.visible = true
		pointer.texture = preload("res://ui/pointer.png")

func is_at_end() -> bool:
	return self.current_block == (self.text.size() - 1)
	
func hide_at_end() -> bool:
	return self.end_type == EndType.NORMAL

func advance_scroll():
	self.current_block += 1
	update_text()
	update_pointer()
	if is_at_end() and not hide_at_end():
		emit_signal("textbox_complete")
	
func _input(event):
	if not self.focused:
		return
	
	if not input_speedbump:
		if event.is_action_pressed("interact"):
			input_speedbump = true
		return
	
	if event.is_action_released("interact"):
		input_speedbump = false
		if is_at_end():
			if hide_at_end():
				hide_box()
				emit_signal("textbox_complete")
		else:
			advance_scroll()
