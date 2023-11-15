extends Node2D

@export_range(1, 10) var MAX_CARD_LENGTH = 7

@export var inital_mana = 2
var cards = preload("res://cards.json").data

@onready var status_effects_container = $"status effects"
@onready var corruption_bar = $"corruption bar"
@onready var mana_container = $"mana container"
@onready var deck = $deck
@onready var played = $"../played"
@onready var score_label = $"corruption bar/score_label"

var card_scene = preload("res://scenes/card.tscn")
var mana_scene = preload("res://scenes/mana.tscn")
var status_effect_label = preload("res://scenes/status-effect.tscn")

var tainted = []


var status_effects = {
	"shield": {
		"value": 0,
		"node": null,
	},
	"poison":  {
		"value": 0,
		"node": null,
	},
	"inheritance": {
		"value": 0,
		"node": null,
	},
}

func _ready():
	for i in range(inital_mana):
		mana_container.add_child(mana_scene.instantiate())



func add_card(card_object):
	var card_instance = card_scene.instantiate()
	deck.add_child(card_instance)
	card_instance.new(card_object)
	

func space_evenly():
	for card_index in range(deck.get_child_count()):
		var card = deck.get_child(card_index)
		card.position.x = (deck.get_child_count() - card_index - 1) * -80

func animate_mana_removal(mana_amount):
	var tween = create_tween()
	
	var mana_scenes = mana_container.get_children()
	
	for i in range(len(mana_scenes) - 1, len(mana_scenes) - 1 - mana_amount, -1):
		tween.tween_property(mana_scenes[i], "scale", Vector2(0, 0), 0.1)
		tween.tween_callback(mana_scenes[i].queue_free)

func animate_mana_creation(mana_amount):
	var tween = create_tween()
	
	for i in range(mana_amount):
		var mana_instance = mana_scene.instantiate()
		mana_instance.scale = Vector2(0, 0)
		mana_container.add_child(mana_instance)
		
		tween.parallel().tween_property(mana_instance, "scale", Vector2(1, 1), 0.1)
	tween.play()
	await tween.finished

func tween_corruption_change(change):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	if change > 0 and change <= status_effects["shield"]["value"]:
		status_effects["shield"]["value"] -= change
			
		if status_effects["shield"]["value"] == 0:
			var mod = status_effects["shield"]["node"].modulate
			mod.a = 0
			tween.tween_property(status_effects["shield"]["node"], "modulate", mod, 0.2)
			tween.tween_callback(func():
				status_effects["shield"]["node"].queue_free()
				status_effects["shield"]["node"] = null)
		else:
			tween.tween_property(status_effects["shield"]["node"], "text", "+%s Shield" % status_effects["shield"]["value"] , 0.2)
	elif status_effects["shield"]["value"] > 0:
		change -= status_effects["shield"]["value"]
		status_effects["shield"]["value"] = 0
		
		var mod = status_effects["shield"]["node"].modulate
		mod.a = 0
		tween.tween_property(status_effects["shield"]["node"], "modulate", mod, 0.2)
		tween.tween_callback(func():
			status_effects["shield"]["node"].queue_free()
			status_effects["shield"]["node"] = null)
		
		tween.tween_property(corruption_bar, "value", clamp(corruption_bar.value + change, 0, 100), 0.5)
	else:
		tween.tween_property(corruption_bar, "value", clamp(corruption_bar.value + change, 0, 100), 0.5)
	
	tween.play()
	await tween.finished

func tween_draw_cards(num_cards):
	for i in range(num_cards):
		if deck.get_child_count() >= MAX_CARD_LENGTH:
			return
			
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		for card in deck.get_children():
			tween.parallel().tween_property(card, "position", Vector2(card.position.x - 80, card.position.y), 0.5).set_delay(0.3)
		
		tween.play()
		
		await tween.finished
		
		var card_instance = card_scene.instantiate()
		deck.add_child(card_instance)
		card_instance.new(cards.pick_random())
		
		card_instance.position.y = 200
		
		tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(card_instance, "position", Vector2(0, 0), 0.75).set_delay(0.2)
		
		tween.play()
		
		await tween.finished
	
	for card_index in range(deck.get_child_count() - 1, -1, -1):
		var card = deck.get_child(card_index)
		
		var tainted_obj = null
		
		for obj in tainted:
			if obj["tainted"] == card.name_string:
				tainted_obj = obj
				break
		
		if tainted_obj != null:
			var tween2 = create_tween()
			tween2.set_trans(Tween.TRANS_CUBIC)
			tween2.tween_property(card, "position", Vector2(card.position.x, card.position.y + 200), 0.2)
			tween2.play()
			await tween2.finished
			
			deck.remove_child(card)
			
			var card_new = card_scene.instantiate()
			deck.add_child(card_new)
			card_new.position.x = card.position.x
			card_new.position.y += 200
			card_new.new(tainted_obj)
			deck.move_child(card_new, card_index)
			
			tween2 = create_tween()
			tween2.set_trans(Tween.TRANS_CUBIC)
			tween2.tween_property(card_new, "position", Vector2(card_new.position.x, card_new.position.y - 200), 0.2)
			tween2.play()
			await tween2.finished

func tween_add_shield(shield_amount):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	
	status_effects["shield"]["value"] += shield_amount
	
	if status_effects["shield"]["node"]:
		tween.tween_property(status_effects["shield"]["node"], "text", "+%s Shield" % status_effects["shield"]["value"], 0.4)
	else:
		status_effects["shield"]["node"] = status_effect_label.instantiate()
		status_effects_container.add_child(status_effects["shield"]["node"])
		status_effects["shield"]["node"].text = "+%s Shield" % status_effects["shield"]["value"]
		status_effects["shield"]["node"].label_settings = status_effects["shield"]["node"].label_settings.duplicate()
		status_effects["shield"]["node"].label_settings.font_color = Color.YELLOW
		status_effects["shield"]["node"].modulate.a = 0
		
		var full = status_effects["shield"]["node"].modulate
		full.a = 100
		
		tween.tween_property(status_effects["shield"]["node"], "modulate", full, 1.2).set_delay(0.2)
	
	tween.play()
	await tween.finished

func tween_add_inheritance():
	if status_effects["inheritance"]["node"]:
		status_effects["inheritance"]["node"].queue_free()
		status_effects["inheritance"]["queue"] = null
	
	status_effects["inheritance"]["value"] = 2
	
	status_effects["inheritance"]["node"] = status_effect_label.instantiate()
	status_effects_container.add_child(status_effects["inheritance"]["node"])
	status_effects["inheritance"]["node"].text = "+2 Mana"
	status_effects["inheritance"]["node"].label_settings = status_effects["inheritance"]["node"].label_settings.duplicate()
	status_effects["inheritance"]["node"].label_settings.font_color = Color.AQUA
	status_effects["inheritance"]["node"].modulate.a = 0
	
	var full = status_effects["inheritance"]["node"].modulate
	full.a = 100
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(status_effects["inheritance"]["node"], "modulate", full, 1.2).set_delay(0.2)
	tween.play()
	
	await tween.finished

func tween_add_poison(poison_amount):
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	
	status_effects["poison"]["value"] += poison_amount
	
	
	if status_effects["poison"]["node"]:
		tween.tween_property(status_effects["shield"]["node"], "text", "+%s Poison" % status_effects["shield"]["value"], 0.4)
	else:
		status_effects["poison"]["node"] = status_effect_label.instantiate()
		status_effects_container.add_child(status_effects["poison"]["node"])
		status_effects["poison"]["node"].text = "+%s Poison" % poison_amount
		status_effects["poison"]["node"].label_settings = status_effects["poison"]["node"].label_settings.duplicate()
		status_effects["poison"]["node"].label_settings.font_color = Color.DARK_RED
		status_effects["poison"]["node"].modulate.a = 0
		
		var full = status_effects["poison"]["node"].modulate
		full.a = 100
		
		
		tween.tween_property(status_effects["poison"]["node"], "modulate", full, 1.2).set_delay(0.2)
	tween.play()
	
	await tween.finished

func tween_delete_random_cards(num_cards):
	for i in range(num_cards):
		await tween_remove_card(deck.get_children().pick_random())

func tween_remove_card(card):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "position", Vector2(card.position.x, card.position.y + 200), 0.5).set_delay(0.2)
	tween.tween_callback(func(): deck.remove_child(card))
	tween.play()

	await tween.finished

	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	for card_index in range(deck.get_child_count()):
		var current_card = deck.get_child(card_index)
		tween.parallel().tween_property(current_card, "position", Vector2((deck.get_child_count() - card_index - 1) * -80, current_card.position.y), 0.4)

	tween.play()

	await tween.finished


func _on_corruption_bar_value_changed(value):
	score_label.text = "%s/100" % round(value)
