extends HBoxContainer

var hovering_card 

@onready var main = $".."
@onready var card_instance = preload("res://scenes/card.tscn")

func _can_drop_data(at_position, data):
	return main.current_player.mana_container.get_child_count() >= data.mana_cost

func _drop_data(at_position, data):
	var other_player = main.player_1 if main.current_player == main.player_2 else main.player_2
	
	var node: Node = data.duplicate()
	node.remove_child(node.find_child("preview_node", false, false))
	node.action_string = data.action_string
	var tainted = data.tainted
	var card_obj = data.card_object_save
	self.add_child(node)

	await main.current_player.tween_remove_card(data)
	
	await main.current_player.animate_mana_removal(data.mana_cost)
	
	if card_obj.has("cost_corruption"):
		await main.current_player.tween_corruption_change(-card_obj["cost_corruption"])
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "scale", Vector2(2, 2), 0.4)
	tween.play()
	
	await tween.finished

	await node.run_action(main.current_player, other_player)
	
	tween = create_tween()
	tween.tween_property(node, "scale", Vector2(0, 0), 0.2)
	tween.tween_callback(node.queue_free)
	
	await tween.finished
	
	if tainted != null:
		main.current_player.tainted.append(card_obj)	
		var cards = main.current_player.deck.get_child_count()
		for card_index in range(cards - 1, -1, -1):
			var card = main.current_player.deck.get_child(card_index)
			if card.name_string == tainted:
				var tween2 = create_tween()
				tween2.set_trans(Tween.TRANS_CUBIC)
				tween2.tween_property(card, "position", Vector2(card.position.x, card.position.y + 200), 0.2)
				tween2.play()
				await tween2.finished
				
				main.current_player.deck.remove_child(card)
				
				var card_new = card_instance.instantiate()
				main.current_player.deck.add_child(card_new)
				card_new.position.x = card.position.x
				card_new.position.y += 200
				card_new.new(card_obj)
				main.current_player.deck.move_child(card_new, card_index)
				
				tween2 = create_tween()
				tween2.set_trans(Tween.TRANS_CUBIC)
				tween2.tween_property(card_new, "position", Vector2(card_new.position.x, card_new.position.y - 200), 0.2)
				tween2.play()
				await tween2.finished
	
	await get_tree().create_timer(1).timeout
