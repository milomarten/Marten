class_name Kitchen
extends Node2D

enum {
	NONE,
	COUNTER
}

var layout = Layout.new(6, 6)

const COUNTER_WALL_LAYER = 0
const COUNTER_OVERHANG_LAYER = 1

const COUNTER_TILESETS = [2, 3] 
const FLOOR_TILESETS = [1, 4]
const WALL_TILESETS = [5]

# All countertops share the same mask: All tiles above
# them can be anything.
const COUNTERTOP_MASK = 0b11111000

# To determine which tile to display, we check the surrounding 
# eight tiles. If the center tile is a Counter tile, 
# it becomes 1, else 0. These are
# compiled into a bit field, with LSB = top-left corner, and MSB
# = bottom-right corner, going from left-to-right, top-to-bottom.

# We then iterate through the COUNTER_RULES rules, if the center is a Counter. If
# the center is not a Counter, we go through the OVERHANG_RULES instead. Each
# "rule" is an array with three elements:
# 1. Mask - 0 indicates "Don't Care" - The tile in that position can be anything and this rule still matches
# 2. Check - Describes the surrounding tiles necessary. "Don't Care" should be 0.
# 3. Tile to use if matches.
# The rule passes if the bitfield, and'ed with the Mask, equals the Check.

# Example: Bottom-left corner
# Mask = 11011000, Check = 00010000
# Combined, this can be expressed as 00X10XXX
# Meaning:
# The three tiles above this one can be anything
# The tile immediately to the left MUST be empty
# The tile immediately to the right MUST be filled
# The tile to the bottom-left can be anything
# The tile immediately below and to the bottom-right MUST be empty

# By a quirk in geometry, the three tiles above are always don't care.
const COUNTER_RULES = [
	[0b11011000, 0b00010000, Vector2i(0, 0)],
	[0b11111000, 0b00011000, Vector2i(1, 0)],
	[0b01111000, 0b00001000, Vector2i(2, 0)],
	[0b01011000, 0b00000000, Vector2i(3, 0)],
	[0b11011000, 0b10010000, Vector2i(4, 0)],
	[0b01111000, 0b00101000, Vector2i(5, 0)],
	[0b11111000, 0b00111000, Vector2i(0, 1)],
	[COUNTERTOP_MASK, 0b11111000, Vector2i(1, 1)],
	[0b11111000, 0b10011000, Vector2i(2, 1)],
	[0b11111000, 0b10111000, Vector2i(3, 1)],
	[COUNTERTOP_MASK, 0b01011000, Vector2i(4, 1)],
	[COUNTERTOP_MASK, 0b01111000, Vector2i(0, 2)],
	[COUNTERTOP_MASK, 0b11011000, Vector2i(1, 2)],
	[COUNTERTOP_MASK, 0b01010000, Vector2i(2, 2)],
	[COUNTERTOP_MASK, 0b01001000, Vector2i(3, 2)],
	[COUNTERTOP_MASK, 0b01101000, Vector2i(0, 3)],
	[COUNTERTOP_MASK, 0b11010000, Vector2i(1, 3)],
	[COUNTERTOP_MASK, 0b01000000, Vector2i(2, 3)],
	[COUNTERTOP_MASK, 0b01100000, Vector2i(3, 3)],
	[COUNTERTOP_MASK, 0b11101000, Vector2i(0, 4)],
	[COUNTERTOP_MASK, 0b11110000, Vector2i(1, 4)],
	[COUNTERTOP_MASK, 0b11000000, Vector2i(2, 4)],
	[COUNTERTOP_MASK, 0b11100000, Vector2i(3, 4)],
	[COUNTERTOP_MASK, 0b01110000, Vector2i(5, 1)],
	[COUNTERTOP_MASK, 0b11001000, Vector2i(6, 1)]
]

# Same as the above rules, but these are for the counter overhang.
const OVERHANG_RULES = [
	[COUNTERTOP_MASK, 0b11101000, Vector2i(4, 2)],
	[COUNTERTOP_MASK, 0b11100000, Vector2i(5, 2)],
	[COUNTERTOP_MASK, 0b11110000, Vector2i(6, 2)],
	[0b11110000, 0b11000000, Vector2i(4, 3)],
	[0b11100000, 0b01000000, Vector2i(5, 3)],
	[0b11101000, 0b01100000, Vector2i(6, 3)],
	[0b11110000, 0b11010000, Vector2i(4, 4)],
	[COUNTERTOP_MASK, 0b11111000, Vector2i(5, 4)],
	[0b11101000, 0b01101000, Vector2i(6, 4)]
]

@onready var map: TileMap = $TileMap
@onready var selector: Sprite2D = $Selector

# Called when the node enters the scene tree for the first time.
func _ready():
	redraw()
	
func _input(event):
	if event is InputEventMouse:
		var mouse_coords = map.get_global_mouse_position()
		var tile_coords = map.local_to_map(mouse_coords)
		selector.position = (tile_coords * 16) + Vector2i(8, 8)
		
		var tile = layout.get_tile_at(tile_coords.x, tile_coords.y)
		selector.frame = 0 if tile == NONE else 1
		
		if event is InputEventMouseButton and event.pressed:
			if tile == NONE and event.button_index == MOUSE_BUTTON_LEFT:
				layout.set_tile(tile_coords.x, tile_coords.y, COUNTER)
				redraw()
			elif tile != NONE and event.button_index == MOUSE_BUTTON_RIGHT:
				layout.set_tile(tile_coords.x, tile_coords.y, NONE)
				redraw()
				
func redraw():
	for x in layout.width_range():
		_create_wall(x)
		for y in layout.height_range(-1):
			if y >= 0:
				_create_floor(x, y)
			_create_counter_tile(x, y)

func _create_counter_tile(x: int, y: int):
	var tile_coords = Vector2i(x, y)
	var center = layout.get_tile_at(x, y)
	var below = layout.get_tile_at(x, y+1)
	if center == NONE and below == NONE:
		# Short Circuit -
		# If this tile and the one below are both empty,
		# there's never gonna be a tile that works.
		map.erase_cell(COUNTER_OVERHANG_LAYER, tile_coords)
		map.erase_cell(COUNTER_WALL_LAYER, tile_coords)
	var bitmask = \
		_get_mask(x-1, y-1, 0) | \
		_get_mask(x, y-1, 1) | \
		_get_mask(x+1, y-1, 2) | \
		_get_mask(x-1, y, 3) | \
		_get_mask(x+1, y, 4) | \
		_get_mask(x-1, y+1, 5) | \
		_get_mask(x, y+1, 6) | \
		_get_mask(x+1, y+1, 7)

	var counter_tiles = COUNTER_TILESETS[layout.counter_theme]
	if center == COUNTER:
		for rule in COUNTER_RULES:
			if bitmask & rule[0] == rule[1]:
				map.set_cell(COUNTER_WALL_LAYER, tile_coords, counter_tiles, rule[2])
				map.erase_cell(COUNTER_OVERHANG_LAYER, tile_coords)
				return
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, counter_tiles, Vector2i(1, 1))
	else:
		for rule in OVERHANG_RULES:
			if bitmask & rule[0] == rule[1]:
				map.set_cell(COUNTER_OVERHANG_LAYER, tile_coords, counter_tiles, rule[2])
				map.erase_cell(COUNTER_WALL_LAYER, tile_coords)
				return
			map.erase_cell(COUNTER_OVERHANG_LAYER, tile_coords)
	
func _get_mask(x: int, y: int, power: int) -> int:
	var tile = layout.get_tile_at(x, y)
	return (1 << power) if tile != NONE else 0

func _create_floor(x: int, y: int):
	var tileset = FLOOR_TILESETS[layout.floor_theme]
	map.set_cell(2, Vector2i(x, y), tileset, Vector2i(x % 2, y % 2))
	
func _create_wall(x: int):
	var tileset = WALL_TILESETS[layout.wall_theme]
	map.set_cell(2, Vector2i(x, -2), tileset, Vector2i(0, 0))
	
class Layout:
	var offset: Vector2i
	var width: int
	var height: int
	var map;
	
	var counter_theme = 1
	var floor_theme = 1
	var wall_theme = 0
	
	func _init(width, height):
		self.height = height
		self.width = width
		self.map = {}
		self.offset = Vector2i.ZERO
	
	func width_range():
		return range(offset.x, width)
	
	func height_range(bound = 0):
		return range(offset.y + bound, height)
	
	func get_tile_at(x: int, y: int) -> int:
		if is_in_bounds(x, y):
			if y in self.map and x in self.map[y]:
				return self.map[y][x]
		return 0
		
	func is_in_bounds(x: int, y:int) -> bool:
		if y < self.offset.y or y >= self.offset.y + self.height:
			return false
		if x < self.offset.x or x >= self.offset.x + self.width:
			return false
		return true
		
	func set_tile(x: int, y: int, tile: int):
		if not self.is_in_bounds(x, y):
			return
		if y not in self.map:
			self.map[y] = {}
		self.map[y][x] = tile
