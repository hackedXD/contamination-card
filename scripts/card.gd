extends TextureRect

var original_scale 
var original_y_position

var mana_cost
var action_string

var tainted = null

var flipped = false

var main_texture

var card_object_save
var card_scene = preload("res://scenes/card.tscn")
@onready var corrupted_particles = $corrupted_particles
var cards = preload("res://cards.json").data
var name_string

func flip():
	flipped = !flipped
	
	if flipped:
		self.texture = preload("res://assets/cards/back.png")
		self.material = null
		corrupted_particles.visible = false
		$container.visible = false
	else:
		self.texture = load("res://assets/cards/" + card_object_save["asset"])
		self.material = load("res://assets/card.gdshader")
		corrupted_particles.visible = true
		$container.visible = true


func run_action(main_player, opponent_player):
	
	var actions = action_string.split("/")
	
	var first_word_regex = RegEx.create_from_string("[a-z]+")
	for action in actions:
		var firstWord = first_word_regex.search(action)
		match firstWord.get_string():
			"corruption":
				var change = int(action.split("+")[1])
				await main_player.tween_corruption_change(change)
			"enemycorruption":
				var change = int(action.split("+")[1])
				await opponent_player.tween_corruption_change(change)
			"shield":
				var change = int(action.split("+")[1])
				await main_player.tween_add_shield(change)
			"oppshield":
				var change = int(action.split("+")[1])
				await opponent_player.tween_add_shield(change)
			"inheritance":
				await main_player.tween_add_inheritance()
			"mana":
				var change = int(action.split("+")[1])
				if change > 0:
					await main_player.animate_mana_creation(change)
				else:
					await main_player.animate_mana_removal(-change)
			"draw":
				var num_cards = int(action.split("+")[1])
				await main_player.tween_draw_cards(num_cards)
			"delete":
				var num_cards = int(action.split("+")[1])
				await main_player.tween_delete_random_cards(num_cards)
			"poisonenemy":
				var poison_amount = int(action.split("+")[1])
				await opponent_player.tween_add_poison(poison_amount)
			"citrus":
				var shield = main_player.deck.get_child_count() * 3
				await main_player.tween_add_shield(shield)
			"forbiddenknowledge":
				
				var tween = create_tween()
				tween.set_trans(Tween.TRANS_CUBIC)
				if main_player.status_effects["poison"]["node"] != null:
					var invis = main_player.status_effects["poison"]["node"].modulate
					invis.a = 0
					tween.parallel().tween_property(main_player.status_effects["poison"]["node"], "modulate", invis, 0.1)
				
				if opponent_player.status_effects["poison"]["node"] != null:
					var invis2 = opponent_player.status_effects["poison"]["node"].modulate
					invis2.a = 0
					tween.parallel().tween_property(opponent_player.status_effects["poison"]["node"], "modulate", invis2, 0.1)
				
				tween.play()
				await tween.finished
				
				main_player.status_effects["poison"]["node"] = {
					"value": 0,
					"node": null
				}
				opponent_player.status_effects["poison"]["node"] = {
					"value": 0,
					"node": null
				}
			"instantnoodles":
				var corruption_original = main_player.corruption_bar.value
				var corruption_change = -1 * floor(corruption_original * 0.2 )
				
				await main_player.tween_corruption_change(corruption_change)
			"pharus":
				var corruption_1 = main_player.corruption_bar.value
				var corruption_2 = opponent_player.corruption_bar.value
				
				await main_player.tween_corruption_change(corruption_2 - corruption_1)
				await opponent_player.tween_corruption_change(corruption_1 - corruption_2)
			"outage":
				var card_count = main_player.deck.get_child_count()
				
				await opponent_player.tween_corruption_change(card_count * 3)
			"taint":
				for card in main_player.deck.get_children():
					for card2 in cards:
						if card2.has("tainted") and card2["tainted"] == card.card_object_save["name"]:
							var tween2 = create_tween()
							tween2.set_trans(Tween.TRANS_CUBIC)
							tween2.tween_property(card, "position", Vector2(card.position.x, card.position.y + 200), 0.2)
							tween2.play()
							await tween2.finished
							
							var card_index = card.get_index()
							main_player.deck.remove_child(card)
							
							var card_new = card_scene.instantiate()
							main_player.deck.add_child(card_new)
							card_new.position.x = card.position.x
							card_new.position.y += 200
							card_new.new(card2)
							main_player.deck.move_child(card_new, card_index)
							
							tween2 = create_tween()
							tween2.set_trans(Tween.TRANS_CUBIC)
							tween2.tween_property(card_new, "position", Vector2(card_new.position.x, card_new.position.y - 200), 0.2)
							tween2.play()
							await tween2.finished
					
				
	

func new(card_object):
	card_object_save = card_object
	
	name_string = card_object["name"]
	var main_texture = load("res://assets/cards/" + card_object["asset"])
	self.texture = main_texture
	$container/name.text = card_object["name"]
	$container/description.text = card_object["effects"]
	
	if card_object.has("tainted"):
		tainted = card_object["tainted"]
		$container/name.label_settings = $container/name.label_settings.duplicate()
		$container/name.label_settings.font_color = Color.RED
		
		corrupted_particles.emitting = true
	
	mana_cost = card_object["cost"]
	action_string = card_object["action"]

func _get_drag_data(at_position):
	if flipped:
		return null
	
	var control_preview = Control.new()
	control_preview.name = "preview_node"
	var clone = self.duplicate()
	clone.scale = Vector2(1, 1)
	clone.position = Vector2(-992, -546)
	clone.modulate.a = 0.5
	control_preview.add_child(clone)
	set_drag_preview(control_preview)
	
	return self

func _on_mouse_entered():
	if flipped:
		return
	
	if get_parent().is_in_group("played"):
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
	if flipped: 
		return
	
	if get_parent().is_in_group("played"):
		return
	
	self.z_index = 0 
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", original_scale, 0.15)
	tween.parallel().tween_property(self, "position", Vector2(position.x, original_y_position), 0.15)
