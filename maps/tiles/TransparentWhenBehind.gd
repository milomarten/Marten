tool
extends KinematicBody2D

export(Texture) var tree_sprite setget set_tree_sprite

func _ready():
	$Sprite.texture = tree_sprite

func _on_Transparency_body_entered(body: Node2D):
	if body.is_in_group("player"):
		$Sprite.self_modulate = Color(1.0, 1.0, 1.0, 0.5)


func _on_Transparency_body_exited(body):
	if body.is_in_group("player"):
		$Sprite.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_tree_sprite(ts):
	tree_sprite = ts
	$Sprite.texture = ts
