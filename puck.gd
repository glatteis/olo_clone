extends RigidBody2D

var is_draggable = false # If the puck is in the "starting position" where it can be dragged by the player
var player # The player associated to this puck

func setup(color, size, owning_player):
	player = owning_player
	# Set correct size and color
	$circle_sprite.modulate = color
	$circle.scale *= size
	$circle_sprite.scale *= size
	$light.scale *= size
	$occluder.scale *= size
	$light.hide()
	# Well... it feels right
	mass *= pow(size * pow(PI, 2), 2)
	set_process(true)

var dragging = false
var drag_start

# Capture when someone wants to flick this puck
func _on_puck_input_event(viewport, event, shape_idx):
	if not is_draggable:
		return
	if event is InputEventMouseButton:
		if event.is_pressed():
			get_parent().start_dragging(get_global_mouse_position(), self)

# If this puck is in its goal area
var currently_in_area = false

# Is this puck in its goal area?
func in_area(position, area):
	return area.x < position.x and area.y > position.x

# If the puck wasn't in the goal area before and is now, send a signal
# When the inverse happens send a signal as well
func _process(delta):
	var game = get_parent()
	if game.turn_unfolding:
		var in_goal_area = in_area(position, player.area)
		if in_goal_area and not currently_in_area:
			currently_in_area = true
			game.puck_entered_area(self)
		elif not in_goal_area and currently_in_area:
			currently_in_area = false
			game.puck_exited_area(self)

# Switch the light that indicates whether or not this puck is in its goal area
func switch_light(on):
	if on:
		$light.show()
		$occluder.hide()
	else:
		$light.hide()
		$occluder.show()


