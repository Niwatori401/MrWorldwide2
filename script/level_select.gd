extends Node2D

var current_child_index : int = 0;



func _ready():
	$MapNode.get_child(0).set_selected(true);


func _process(delta):
	if Input.is_action_just_pressed("left"):
		current_child_index -= 1;
		if current_child_index < 0:
			current_child_index = $MapNode.get_child_count() - 1;
		update_selected_node();

	if Input.is_action_just_pressed("right"):
		current_child_index += 1;
		current_child_index %= $MapNode.get_child_count();
		update_selected_node();
	
func update_selected_node():
	var previous_index = current_child_index - 1;
	var next_index = current_child_index + 1;
	
	if previous_index < 0:
		previous_index = $MapNode.get_child_count() - 1;
	
	if next_index == $MapNode.get_child_count():
		next_index = 0;

	$MapNode.get_child(previous_index).set_selected(false);
	$MapNode.get_child(next_index).set_selected(false);
	$MapNode.get_child(current_child_index).set_selected(true);
