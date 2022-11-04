@tool
extends CharacterBody2D

@export var tree_sprite: Texture2D :
	get:
		return tree_sprite # TODOConverter40 Non existent get function 
	set(mod_value):
		mod_value  # TODOConverter40 Copy here content of set_tree_sprite

func _ready():
	$Sprite2D.texture = tree_sprite

func _on_Transparency_body_entered(body: Node2D):
	if body.is_in_group("player"):
		$Sprite2D.self_modulate = Color(1.0, 1.0, 1.0, 0.5)


func _on_Transparency_body_exited(body):
	if body.is_in_group("player"):
		$Sprite2D.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_tree_sprite(ts):
	tree_sprite = ts
	$Sprite2D.texture = ts
