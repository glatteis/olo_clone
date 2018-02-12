extends Node

var score = 0
var pucks # Array of floats that represent the sizes of pucks
var color # Color that the player's pucks will have
var dark_color
var spawn_point # The location (Vector2) that the player's pucks will spawn at
var area # The player's goal area
var scoreboard # The label for the score

var puck_sizes = [.8, 1.2, 1.5]

func _init():
	pucks = puck_sizes + puck_sizes + puck_sizes + puck_sizes

func setup():
	dark_color = color.darkened(0.7)

# Gets a random puck from the remaining pucks
func get_puck():
	var puck = pucks[randi() % pucks.size()]
	pucks.remove(puck)
	return puck

func update_score():
	scoreboard.set_text(str(score))