extends Node2D

@export_range(1, 10) var MAX_CARD_LENGTH = 7

var mana = 2

@onready var corruption_bar = $"corruption bar"
@onready var mana_container = $"mana container"
@onready var deck = $deck
@onready var played = $"../played"

var card_scene = preload("res://scenes/card.tscn")
var mana_scene = preload("res://scenes/mana.tscn")

func _ready():
	for i in range(mana):
		mana_container.add_child(mana_scene.instantiate())

func add_card(card_object):
	var card_instance = card_scene.instantiate()
	card_instance.played = played
	deck.add_child(card_instance)
	card_instance.new(card_object)

func animate_mana_removal(mana_amount):
	print(mana_amount)
	var tween = create_tween()
	
	var mana_scenes = mana_container.get_children()
	
	for i in range(len(mana_scenes) - 1, len(mana_scenes) - 1 - mana_amount, -1):
		tween.tween_property(mana_scenes[i], "scale", Vector2(0, 0), 0.1)
		tween.tween_callback(mana_scenes[i].queue_free)
		mana -= 1
