extends Node2D

enum {
	NONE,
	COUNTER
}

var layout = SillyLayout.new(12, 12)

const COUNTER_WALL_LAYER = 0
const COUNTER_OVERHANG_LAYER = 1

const KITCHEN_TILESET = 2

# To determine which tile to display, we check the surrounding 
# eight tiles and compare with the center. If the center tile
# matches a surrounding tile, it becomes 1, else 0. These are
# compiled into a bitmask, with LSB = top-left corner, and MSB
# = bottom-right corner, going from left-to-right, top-to-bottom.

# Using the computed bitmask, we determine the tile by
# doing a bitwise and with each *_MASK, and comparing it to *_CHECK.
# *_MASK fields effectively indicate "Don't Care" states - 0 means "Don't Care".
# By blanking out the don't cares, *_CHECK then indicates the actual pattern.

# Code: B = Bottom, L = Left Edge, R = Right Edge,
# IL = Inverted Left, IR = Inverted Right
# LR = Left and Right Edge, ILR = Inverted Left and Right Edge
const BL_MASK = 0b11011000
const BL_CHECK = 0b00010000
const B_MASK = 0b11111000
const B_CHECK = 0b00011000
const BR_MASK = 0b01111000
const BR_CHECK = 0b00001000
const BLR_MASK = 0b01011000
const BLR_CHECK = 0b00000000
const BL_IR_MASK = 0b11011000
const BL_IR_CHECK = 0b10010000
const BR_IL_MASK = 0b01111000
const BR_IL_CHECK = 0b00101000
const B_IL_MASK = 0b11111000
const B_IL_CHECK = 0b00111000
const B_IR_MASK = 0b11111000
const B_IR_CHECK = 0b10011000
const B_ILR_MASK = 0b11111000
const B_ILR_CHECK = 0b10111000

# All countertops share the same mask: All tiles above
# them can be anything.
const COUNTERTOP_MASK = 0b11111000

# CODE:
# L = Left Edge, R = Right Edge
# LUC = Left Edge, widens upwards
# RUC = Right Edge, widens upwards
# LLC = Left Edge, widens downwards
# RLC = Right Edge, widens downwards
# CENTER = No edges
const M_CENTER_CHECK = 0b11111000
const M_LUC_RUC_CHECK = 0b01011000
const M_RUC_CHECK = 0b01111000
const M_LUC_CHECK = 0b11011000
const M_RUC_L_CHECK = 0b01010000
const M_LUC_R_CHECK = 0b01001000
const MR_CHECK = 0b01101000
const ML_CHECK = 0b11010000
const MLR_CHECK = 0b01000000
const M_LLC_R_CHECK = 0b01100000
const M_RLC_L_CHECK = 0b11000000
const M_RLC_CHECK = 0b11101000
const M_LLC_CHECK = 0b11110000
const M_LLC_RLC_CHECK = 0b11100000
const M_LLC_RUC_CHECK = 0b01110000
const M_RLC_LUC_CHECK = 0b11001000

# Code:
# L = Left Edge, R = Right Edge
# IL = Inverted Left, IR = Inverted Right
const EIL_CHECK = 0b11101000
const E_CHECK = 0b11100000
const EIR_CHECK = 0b11110000

const EL_MASK = 0b11110000
const EL_CHECK = 0b11000000
const ELR_MASK = 0b11100000
const ELR_CHECK = 0b01000000
const ER_MASK = 0b11101000
const ER_CHECK = 0b01100000

const EL_IR_MASK = 0b11110000
const EL_IR_CHECK = 0b11010000
const EIL_IR_CHECK = 0b11111000
const ER_IL_MASK = 0b11101000
const ER_IL_CHECK = 0b01101000

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
	# We start at -1, because a counter might be at y=0,
	# and we need to draw overhangs for those.
	for y in layout.height_range(-1):
		for x in layout.width_range():
			_determine_tile_for(x, y)

func _determine_tile_for(x: int, y: int):
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

	if center == COUNTER:
		if bitmask & BL_MASK == BL_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(0, 0))
		elif bitmask & B_MASK == B_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(1, 0))
		elif bitmask & BR_MASK == BR_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(2, 0))
		elif bitmask & BLR_MASK == BLR_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(3, 0))
		elif bitmask & BL_IR_MASK == BL_IR_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(4, 0))
		elif bitmask & BR_IL_MASK == BR_IL_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(5, 0))
		elif bitmask & B_IL_MASK == B_IL_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(0, 1))
		elif bitmask & COUNTERTOP_MASK == M_CENTER_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(1, 1))
		elif bitmask & B_IR_MASK == B_IR_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(2, 1))
		elif bitmask & B_ILR_MASK == B_ILR_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(3, 1))
		elif bitmask & COUNTERTOP_MASK == M_LUC_RUC_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(4, 1))
		elif bitmask & COUNTERTOP_MASK == M_RUC_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(0, 2))
		elif bitmask & COUNTERTOP_MASK == M_LUC_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(1, 2))
		elif bitmask & COUNTERTOP_MASK == M_RUC_L_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(2, 2))
		elif bitmask & COUNTERTOP_MASK == M_LUC_R_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(3, 2))
		elif bitmask & COUNTERTOP_MASK == MR_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(0, 3))
		elif bitmask & COUNTERTOP_MASK == ML_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(1, 3))
		elif bitmask & COUNTERTOP_MASK == MLR_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(2, 3))
		elif bitmask & COUNTERTOP_MASK == M_LLC_R_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(3, 3))
		elif bitmask & COUNTERTOP_MASK == M_RLC_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(0, 4))
		elif bitmask & COUNTERTOP_MASK == M_LLC_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(1, 4))
		elif bitmask & COUNTERTOP_MASK == M_RLC_L_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(2, 4))
		elif bitmask & COUNTERTOP_MASK == M_LLC_RLC_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(3, 4))
		elif bitmask & COUNTERTOP_MASK == M_LLC_RUC_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(5, 1))
		elif bitmask & COUNTERTOP_MASK == M_RLC_LUC_CHECK:
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(6, 1))
		else:
			# Default to filled...Best representation I suppose
			map.set_cell(COUNTER_WALL_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(1, 1))
		map.erase_cell(COUNTER_OVERHANG_LAYER, tile_coords)
	else:
		if bitmask & COUNTERTOP_MASK == EIL_CHECK:
			map.set_cell(COUNTER_OVERHANG_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(4, 2))
		elif bitmask & COUNTERTOP_MASK == E_CHECK:
			map.set_cell(COUNTER_OVERHANG_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(5, 2))
		elif bitmask & COUNTERTOP_MASK == EIR_CHECK:
			map.set_cell(COUNTER_OVERHANG_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(6, 2))
		elif bitmask & EL_MASK == EL_CHECK:
			map.set_cell(COUNTER_OVERHANG_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(4, 3))
		elif bitmask & ELR_MASK == ELR_CHECK:
			map.set_cell(COUNTER_OVERHANG_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(5, 3))
		elif bitmask & ER_MASK == ER_CHECK:
			map.set_cell(COUNTER_OVERHANG_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(6, 3))
		elif bitmask & EL_IR_MASK == EL_IR_CHECK:
			map.set_cell(COUNTER_OVERHANG_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(4, 4))
		elif bitmask & COUNTERTOP_MASK == EIL_IR_CHECK:
			map.set_cell(COUNTER_OVERHANG_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(5, 4))
		elif bitmask & ER_IL_MASK == ER_IL_CHECK:
			map.set_cell(COUNTER_OVERHANG_LAYER, tile_coords, KITCHEN_TILESET, Vector2i(6, 4))
		else:
			map.erase_cell(COUNTER_OVERHANG_LAYER, tile_coords)
		map.erase_cell(COUNTER_WALL_LAYER, tile_coords)
	
func _get_mask(x: int, y: int, power: int) -> int:
	var tile = layout.get_tile_at(x, y)
	return (1 << power) if tile != NONE else 0

class SillyLayout:
	var offset: Vector2i
	var width: int
	var height: int
	var map;
	
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
