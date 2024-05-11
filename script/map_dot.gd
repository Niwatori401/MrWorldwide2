extends Node2D

@export var level_scene_path : String;
const RADIANS_PER_SECOND = 1.5 * PI;
var is_selected := false;
 
func _ready():
	$RotatingArc.visible = false;
	
func _process(delta):
	if is_selected:
		$RotatingArc.rotate(RADIANS_PER_SECOND * delta);
	
	if Input.is_action_just_pressed("action") and is_selected:
		load_level();
		
	if Input.is_action_just_pressed("number_1"):
		set_selected(!is_selected);
	
func set_selected(is_selected : bool):
	self.is_selected = is_selected;
	$RotatingArc.visible = is_selected;

func load_level():
	get_tree().change_scene_to_file(level_scene_path);
