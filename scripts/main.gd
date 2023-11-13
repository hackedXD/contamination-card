extends Node2D
@onready var deck: TextureRect = $deck

var original_deck_transform = {
	"position": Vector2.ZERO,
	"scale": Vector2.ZERO
}
var card_scene = preload("res://scenes/card.tscn")

var cards = preload("res://cards.json").data

@onready var hand = $hand

func _ready():
	for card in cards:
		var card_instance = card_scene.instantiate()
		hand.add_child(card_instance)
		card_instance.new(card)




func _on_deck_mouse_entered():
	for key in original_deck_transform.keys():
		original_deck_transform[key] = deck[key]
	var tween = create_tween()
	tween.tween_property(deck, "scale", deck.scale * 1.2, 0.1)




func _on_deck_mouse_exited():
	var tween = create_tween()
	for key in original_deck_transform.keys():
		tween.tween_property(deck, key, original_deck_transform[key], 0.1)


func _on_hand_child_entered_tree(node):
	for i in range(hand.get_child_count()):
		var card_node = hand.get_child(i)
		card_node.position.x = i * 50


func _on_deck_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var random_card = cards.pick_random()
		var card_instance = card_scene.instantiate()
		hand.add_child(card_instance)
		card_instance.new(random_card) 
