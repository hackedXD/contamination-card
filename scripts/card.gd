extends Control

@onready var name_decoration: Sprite2D = $"name decoration"
@onready var frame_decoration: Sprite2D = $"frame decoration"
@onready var desc_decoration: Sprite2D = $"desc decoration"
@onready var name_label = $"name decoration/name label"
@onready var description_label = $"desc decoration/description label"



var original_card_scale = Vector2.ZERO
var mouse_over = false
var dragging = false
var relative_dragging_position = Vector2.ZERO

const rarity_positions = {
	"name": [16, 135, 252],
	"frame": [22, 140, 257],
	"desc": [17, 135, 252]
}

func _ready():
	self.position.y = 0
	self.size = Vector2(100, 128)
	self.scale = Vector2(1, 1)
	self.pivot_offset = Vector2(50, 128)

func new(card_object):
	name_decoration.region_rect.position.x = rarity_positions["name"][card_object["rarity"] - 1]
	frame_decoration.region_rect.position.x = rarity_positions["frame"][card_object["rarity"] - 1]
	desc_decoration.region_rect.position.x = rarity_positions["desc"][card_object["rarity"] - 1]
	
	name_label.text = card_object["name"]
	description_label.text = card_object["effects"]

func _on_mouse_entered():
	mouse_over = true
	original_card_scale = scale
	z_index = 10
	var tween = create_tween()
	tween.tween_property(self, "scale", scale * 1.2, 0.1)



func _on_mouse_exited():
	mouse_over = false
	z_index = 0
	var tween = create_tween()
	tween.tween_property(self, "scale", original_card_scale, 0.1)


func _on_gui_input(event):
	if (event is InputEventMouseButton):
		dragging = event.pressed
		relative_dragging_position = event.position
	elif (event is InputEventMouseMotion and dragging):
		global_position = get_global_mouse_position()
	
