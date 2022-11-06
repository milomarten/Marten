@tool
extends CharacterBody2D

@export var tree_sprite: Texture2D :
	get:
		return $Sprite.texture
	set(mod_value):
		$Sprite.texture = mod_value

func _ready():
	$Sprite.texture = tree_sprite

func _on_Transparency_body_entered(body: Node2D):
	if body.is_in_group("player"):
		$Sprite.self_modulate = Color(1.0, 1.0, 1.0, 0.5)

func _on_Transparency_body_exited(body):
	if body.is_in_group("player"):
		$Sprite.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
