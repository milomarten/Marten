extends SubViewport

# This is still a work in progress. Eventually, this will create a texture that
# can then be fed into any OW Sprite

enum Body {
	Fox,
	ArcticFox
}

const bodies = [
	preload("res://sprites/npcs/fox.png"),
	preload("res://sprites/npcs/arcticfox-summer.png")
]

@export var body: Body

@onready var body_node: Sprite2D = $Body

func _ready():
	change()
	
func change():
	var base = bodies[self.body]
	body_node.texture = base

func texture() -> Texture:
	return self.get_texture()
