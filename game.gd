extends Node2D


onready var Puck = load("res://puck.tscn")
const Player = preload("res://player.gd")
# The two competing players.
var player1 = Player.new()
var player2 = Player.new()
# For convenience, a list
var players = [player1, player2]
# Stores the player that is on turn.
# The first value will be immediately inverted
onready var turn_player = players[randi() % players.size()]

# For showing the drag
onready var drag_arrow = load("res://drag_arrow.tscn").instance()

# The bounds of the respective areas on the field, in (x, x) coordinate tuples
# TODO maybe find a less confusing data structure for this
# TODO maybe support y values
export(Vector2) var home_a_bounds
export(Vector2) var home_b_bounds
export(Vector2) var capture_a_bounds
export(Vector2) var capture_b_bounds

func _init():
	randomize()

func _ready():
	# Set Godot Params
	set_process_input(true)
	
	# Set Player Params
	player1.color = Color(.8, 0, 0)
	player2.color = Color(0, .8, 0)
	
	# The spawn point of the player's pucks
	player1.spawn_point = Vector2((home_a_bounds.x + home_a_bounds.y) / 2, 0)
	player2.spawn_point = Vector2((home_b_bounds.x + home_b_bounds.y) / 2, 0)
	
	# The score label
	player1.scoreboard = $score_a
	player2.scoreboard = $score_b
	
	# The goal area where pucks will lie to count as points
	player1.area = capture_a_bounds
	player2.area = capture_b_bounds
	
	# Call setup methods in players
	for p in players:
		p.setup()
	
	# Start first turn
	new_turn()

# Sets up a new turn for the next player
func new_turn():
	# Swap players to next player
	switch_players()
	# The size (radius) of the next puck
	var next_puck_size = turn_player.get_puck()
	
	# Make and setup next puck
	var puck = Puck.instance()
	puck.setup(turn_player.color, next_puck_size, turn_player)
	puck.position = turn_player.spawn_point
	# Set puck to current "draggable" (movable puck)
	puck.is_draggable = true
	add_child(puck)

# Switches to next player
func switch_players():
	var player_index = players.find(turn_player)
	player_index = (player_index + 1) % players.size()
	turn_player = players[player_index]

# If the player is dragging a puck right now
var dragging = false
# Start of this drag
var drag_start
# Puck that is dragged
var drag_puck
# The minimum distance you can drag the puck (below it will just cancel)
const min_drag_range = 200
# The maximum distance you can drag the puck
const max_drag_range = 800

# If a puck has been dragged and the turn is going on right now
var turn_unfolding = false

# This function is called by the puck that has been clicked
func start_dragging(start, puck):
	dragging = true
	drag_start = start
	drag_puck = puck
	drag_arrow.position = puck.position
	drag_arrow.hide()
	add_child(drag_arrow)

func _input(event):
	# Handles the dragging stuff / arrow updating and firing the puck
	if not dragging:
		return
	# The clamped delta between current mouse position and the puck where we started
	var drag_delta = (get_global_mouse_position() - drag_start).clamped(max_drag_range)
	if event is InputEventMouseButton:
		# If we are over the min drag range and dragging, fire the puck!
		if drag_delta.length() > min_drag_range:
			var flick_delta = Vector2(abs(pow(2, (drag_delta / max_drag_range).x) - 1), 
					abs(pow(2, (drag_delta / max_drag_range).y) - 1))
			print(drag_delta.x)
			print(pow(2, 1.5))
			drag_puck.apply_impulse(Vector2(0, 0), drag_delta * flick_delta * 1000)
			drag_puck.is_draggable = false
			turn_unfolding = true
		dragging = false
		remove_child(drag_arrow)
	# Move/show/hide the arrow if nessecary
	elif event is InputEventMouseMotion:
		if drag_delta.length() > min_drag_range:
			drag_arrow.show()
		else:
			drag_arrow.hide()
		drag_arrow.rotation = drag_delta.angle()
		drag_arrow.region_rect.size.x = drag_delta.length() / 2
		var drag_ratio = (drag_delta.length() - min_drag_range) / (max_drag_range - min_drag_range)
		drag_arrow.modulate = Color(drag_ratio, 1-drag_ratio, 0, .5)
		pass


# Called by puck when it enters its respective area
func puck_entered_area(puck):
	puck.switch_light(true)
	puck.player.score += 1
	puck.player.update_score()
	

# Called by puck when it exits its respective area
func puck_exited_area(puck):
	puck.switch_light(false)
	puck.player.score -= 1
	puck.player.update_score()

func _process(delta):
	if not turn_unfolding:
		return
	# See if everything has stopped
	var everything_has_stopped = true
	for child in get_children():
		if child is RigidBody2D and child.get_linear_velocity().length() > 2:
			everything_has_stopped = false
			break
	if everything_has_stopped:
		# Stop everything
		for child in get_children():
			if child is RigidBody2D:
				child.set_linear_velocity(Vector2(0, 0))
		turn_unfolding = false
		new_turn()

func _draw():
	# Draw the player area colors
	for p in players:
		draw_rect(Rect2(p.area.x, -500, p.area.y - p.area.x, 1000), p.dark_color)
	