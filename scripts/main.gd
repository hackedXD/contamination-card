extends Node2D

var cards = preload("res://cards.json").data

@onready var player_1 = $player1
@onready var player_2 = $player2
@onready var current_player = player_1
@onready var next_button = $next_button
@onready var played = $played


var original_next_button_x_position
var next_button_tweening = false

func _ready():
	player_1.position.y += 300
	player_2.position.y -= 300
	
	for i in range(5):
		player_1.add_card(cards.pick_random())
	
	for i in range(5):
		player_2.add_card(cards.pick_random())
	
	for card in player_2.deck.get_children():
		card.flip()
	
	player_1.space_evenly()
	player_2.space_evenly()

func _input(event):
	if event.is_action_pressed("start"):
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(player_1, "position", Vector2(player_1.position.x, player_1.position.y - 300), 0.3)
		tween.parallel().tween_property(player_2, "position", Vector2(player_2.position.x, player_2.position.y + 300), 0.3)


func next_button_right():
	if next_button_tweening:
		var tween = create_tween()
		tween.tween_property(next_button, "position", Vector2(original_next_button_x_position + 10, next_button.position.y), 0.5).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(next_button_left)

func next_button_left():
	var tween = create_tween()
	tween.tween_property(next_button, "position", Vector2(original_next_button_x_position, next_button.position.y), 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(next_button_right)

func _on_next_button_mouse_entered():
	if original_next_button_x_position == null:
		original_next_button_x_position = next_button.position.x
	
	next_button_tweening = true
	next_button_right()

func _on_next_button_mouse_exited():
	next_button_tweening = false


func _on_next_button_pressed():
	var other_player = player_1 if current_player == player_2 else player_2
	
	var played_cards = played.get_children()
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(player_1, "rotation", player_1.rotation + PI, 0.5)
	tween.parallel().tween_property(player_2, "rotation", player_2.rotation + PI, 0.5)
	tween.play()
	
	await tween.finished
	
	var temp = current_player
	current_player = other_player
	other_player = temp
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(current_player.deck, "position", Vector2(current_player.deck.position.x, current_player.deck.position.y + 200), 0.15)
	tween.parallel().tween_property(other_player.deck, "position", Vector2(other_player.deck.position.x, other_player.deck.position.y - 200), 0.15)
	
	tween.play()
	await tween.finished
	
	for card in current_player.deck.get_children() + other_player.deck.get_children():
		card.flip()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(current_player.deck, "position", Vector2(current_player.deck.position.x, current_player.deck.position.y - 200), 0.15)
	tween.parallel().tween_property(other_player.deck, "position", Vector2(other_player.deck.position.x, other_player.deck.position.y + 200), 0.15)
	
	tween.play()
	await tween.finished
	
	
	await current_player.animate_mana_creation(2)
	await current_player.tween_draw_cards(2)
	
	if current_player.status_effects["inheritance"]["value"] > 0:
		await current_player.animate_mana_creation(current_player.status_effects["inheritance"]["value"])
		
		tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		
		var invis = current_player.status_effects["inheritance"]["node"].modulate
		invis.a = 0
		
		tween.tween_property(current_player.status_effects["inheritance"]["node"], "modulate", invis, 0.1)
		tween.play()
		
		await tween.finished
		
		current_player.status_effects["inheritance"]["node"].queue_free()
		current_player.status_effects["inheritance"] = {
			"value": 0,
			"node": null
		}
	
	if current_player.status_effects["poison"]["value"] > 0:
		await current_player.tween_corruption_change(-current_player.status_effects["poison"]["value"])
		current_player.status_effects["poison"]["value"] -= 1
		tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		
		if current_player.status_effects["poison"]["value"] == 0:
			var invis = current_player.status_effects["poison"]["node"].modulate
			invis.a = 0
			
			tween.tween_property(current_player.status_effects["poison"]["node"], "modulate", invis, 0.1)
			current_player.status_effects["poison"]["node"] = null
		else:
			print("hello")
			tween.tween_property(current_player.status_effects["poison"]["node"], "text", "+%s Poison" % current_player.status_effects["poison"]["value"], 0.2)
		
		tween.play()
		
		await tween.finished
