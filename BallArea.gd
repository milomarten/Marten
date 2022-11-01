tool
extends Area2D

export(Vector2) var spawn_point

onready var ball_generator = load("res://sprites/Ball.tscn")
onready var place = get_node("../OWField")

# Called when the node enters the scene tree for the first time.
func _ready():
	var ball = ball_generator.instance()
	ball.position = spawn_point
	place.add_child(ball)

func _on_BallArea_body_exited(body):
	if body.is_in_group("ball"):
		
		body.queue_free()
		
		var ball = ball_generator.instance()
		ball.position = spawn_point
		place.add_child(ball)