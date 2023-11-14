extends TextureRect

@export var played: Node

var original_scale 
var original_y_position

var mana_cost
var action_string


func run_action(main_player, opponent_player):
	
	var actions = action_string.split("/")
	
	var first_word_regex = RegEx.new()
	var error = first_word_regex.compile("/[a-z]/g")
	if error:
		print(error)
	for action in actions:
		print(action)
		print(first_word_regex.get_pattern())
		var firstWord = first_word_regex.search(action)
		
		print(action, firstWord.get_string())
	
	

func new(card_object):
	self.texture = load("res://assets/card/" + card_object["asset"])
	$name.text = card_object["name"]
	$description.text = card_object["effects"]
	mana_cost = card_object["cost"]
	action_string = card_object["action"]

func _get_drag_data(at_position):
	var control_preview = Control.new()
	var clone = self.duplicate()
	clone.scale = Vector2(1, 1)
	clone.position = Vector2(-992, -546)
	clone.modulate.a = 0.5
	control_preview.add_child(clone)
	set_drag_preview(control_preview)
	
	return self

func _on_mouse_entered():
	if get_parent() == played:
		return
	
	if original_scale == null:
		original_scale = scale
	
	if original_y_position == null:
		original_y_position = position.y
	
	self.z_index = 10
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", original_scale * 1.2, 0.15)
	tween.parallel().tween_property(self, "position", Vector2(position.x, original_y_position - 100), 0.15)


func _on_mouse_exited():
	if get_parent() == played:
		return
	
	self.z_index = 0 
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", original_scale, 0.15)
	tween.parallel().tween_property(self, "position", Vector2(position.x, original_y_position), 0.15)
