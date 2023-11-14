extends Node2D
@onready var deck: TextureRect = $deck

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
	
	for i in range(6):
		player_1.add_card(cards.pick_random())
		player_2.add_card(cards.pick_random())

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
	var played_cards = played.get_children()
	
	for card in played_cards:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(card, "scale", Vector2(2, 2), 0.4)
		tween.play()
		
		await tween.finished
		
		var other_player = player_1 if current_player == player_2 else player_1
		card.run_action(current_player, other_player)
		
		tween = create_tween()
		tween.tween_property(card, "scale", Vector2(0, 0), 0.2)
		tween.tween_callback(card.queue_free)
		
		await tween.finished
		
		await get_tree().create_timer(1).timeout
		
		
