extends HBoxContainer

var hovering_card 

@onready var main = $".."


func _can_drop_data(at_position, data):	
	return main.current_player.mana >= data.mana_cost

func _drop_data(at_position, data):
	data.reparent(self)
	
	main.current_player.animate_mana_removal(data.mana_cost)
