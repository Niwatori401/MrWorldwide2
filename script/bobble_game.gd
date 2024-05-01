extends Node2D

signal game_over;

@export var background_sprite : Texture2D;
@export var tray_sprite : Texture2D;

@export var bobble_set : Array[PackedScene];
@export var SECONDS_BETWEEN_SHOTS : float = 1.0;
@export var initial_rows_count : int = 4;
var cur_seconds_after_shot : float = 0;

const MAX_ROTATION_ABSOLUTE : float = deg_to_rad(80);
const ROTATION_SPEED : float = 3.0;
const LAUNCH_SPEED_MAGNITUDE : float = 900;

const RAYCAST_COLLISION_LAYER : int = 0b0010;
const BOBBLE_COLLISION_LAYER : int = 0b0001;

const KILL_LINE_PERCENTAGE : float = 0.85;

const MAX_POP_PITCH : float = 1.3;
const MIN_POP_PITCH : float = 0.7;

var food_prop_blueprint = preload("res://scene/food_prop.tscn");
const FOOD_PROP_X_VELOCITY_RANGE := Vector2(-100, 100);
const FOOD_PROP_Y_VELOCITY_RANGE := Vector2(-300, -500);


var static_bobble_blueprint : PackedScene = preload("res://scene/static_bobble.tscn");
var current_rotation = 0;

@export var dot_textures : Array[Texture2D];
var dot_texture_index : int = 0;
const dot_seconds_per_cycle : float = 0.2;
var elapsed_seconds_for_dot : float = 0;

@export var cell_count_horizontal := 7;
var bubble_radius : float;
var row_height : float;

var row_offset_count : int = 0;
var next_bobble;
var parent_level;
var shot_cooldown_finished := true;

var flying_bobble_count : int = 0;

var help_lines = [];

var bubble_grid : Array[Array];

var progress_circle_points := PackedVector2Array();
const ANGLE_PER_POINT_RAD : float = deg_to_rad(2);
const PROGRESS_CIRCLE_RADIUS : float = 30;
const CIRCLE_ANGLE_OFFSET : float = deg_to_rad(270);
@export var seconds_per_row : float = 9;
@export var time_decrease_per_row : float = 0.2;
@export var min_seconds_per_row : float = 5;
var elapsed_seconds_for_new_row : float = 0;


# These are used to prevent pressing left and right cancelling each other out for input.
var override_left := false;
var override_right := false;

func _ready():
	# level.tscn
	parent_level = get_parent();
	connect("game_over", parent_level.game_over)
	init_background_progress_bar_points();
	init_exported_sprites();
	bubble_radius = ($BackgroundSprite.get_rect().size[0] * $BackgroundSprite.global_scale[0]) / (2 * cell_count_horizontal);
	row_height = sqrt(3) * bubble_radius;
	add_hitboxes_for_help_lines();
	init_grid();
	set_next_bobble();
	$Tray/Gun/BobbleProp.scale_bobble(bubble_radius);
	lock_kill_line_to_grid();

func _process(delta):
	
	if not should_spawn_next_row():
		elapsed_seconds_for_new_row += delta;
	elif flying_bobble_count == 0:
		elapsed_seconds_for_new_row -= seconds_per_row;
		add_next_row();
#
	set_progress_to_next_row(elapsed_seconds_for_new_row / seconds_per_row)
	
	$Tray/ProgressBar/ProgressPolygonDisabledShader.visible = should_spawn_next_row() and flying_bobble_count > 0;
	
	
	if Input.is_action_pressed("kill"):
		get_tree().quit();
	
	if Input.is_action_just_pressed("debug_1"):
		add_next_row();

	
	if Input.is_action_pressed("fullscreen"):
		if get_viewport().mode == Window.MODE_MAXIMIZED:
			get_viewport().mode = Window.MODE_FULLSCREEN;
		else:
			get_viewport().mode = Window.MODE_MAXIMIZED;
	
	if not shot_cooldown_finished:
		cur_seconds_after_shot += delta;
	
		if cur_seconds_after_shot >= SECONDS_BETWEEN_SHOTS:
			cur_seconds_after_shot = 0;
			shot_cooldown_finished = true;
			set_next_bobble();
			$Tray/Gun/BobbleProp.visible = true;
	
	var speed_multiplier = 1.0;
	if Input.is_action_pressed("shift"):
		speed_multiplier = 0.2;
	
	if Input.is_action_just_pressed("left"):
		override_right = true;
		override_left =false;
	if Input.is_action_just_pressed("right"):
		override_left = true;
		override_right = false;
	
	if override_left and Input.is_action_just_released("right"):
		override_left = false;
	if override_right and Input.is_action_just_released("left"):
		override_right = false;
	
	if not override_left and Input.is_action_pressed("left"):
		try_rotate_left(delta, speed_multiplier);
	if not override_right and Input.is_action_pressed("right"):
		try_rotate_right(delta, speed_multiplier);
	if Input.is_action_just_pressed("up") and shot_cooldown_finished and not should_spawn_next_row():
		fire_bobble();
	
	update_help_lines(delta);
	
	$Tray/Gun/GunBarrel.rotation = self.current_rotation;


func _physics_process(_delta):
	calculate_raycast_help_lines();

func update_help_lines(delta):
	elapsed_seconds_for_dot += delta;
	if elapsed_seconds_for_dot >= dot_seconds_per_cycle:
		elapsed_seconds_for_dot -= dot_seconds_per_cycle;
	
	for c in $HelpLines.get_children():
		$HelpLines.remove_child(c);
	
	for coord in help_lines:
		var new_line = Line2D.new();
		$HelpLines.add_child(new_line);
		new_line.texture = dot_textures[int(round((elapsed_seconds_for_dot / dot_seconds_per_cycle) * (dot_textures.size() - 1)))];
		new_line.begin_cap_mode = Line2D.LINE_CAP_ROUND;
		new_line.end_cap_mode = Line2D.LINE_CAP_ROUND;
		new_line.texture_mode = Line2D.LINE_TEXTURE_TILE;
		new_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED;
		new_line.add_point(new_line.to_local(coord[0]));
		new_line.add_point(new_line.to_local(coord[1]));

func add_hitboxes_for_help_lines():
	var left_wall = $Hitborder/LeftWall.duplicate();
	var right_wall = $Hitborder/RightWall.duplicate();
	var top_wall = $Hitborder/TopWall.duplicate();
	
	left_wall.add_to_group("rayflector");
	right_wall.add_to_group("rayflector");
	
	left_wall.get_child(0).debug_color = Color(0.2, 1.0, 0.7, 0.8);
	right_wall.get_child(0).debug_color = Color(0.2, 1.0, 0.7, 0.8);
	top_wall.get_child(0).debug_color = Color(0.2, 1.0, 0.7, 0.8);
	
	left_wall.collision_layer = RAYCAST_COLLISION_LAYER;
	right_wall.collision_layer = RAYCAST_COLLISION_LAYER;
	top_wall.collision_layer = RAYCAST_COLLISION_LAYER;
	top_wall.collision_mask = RAYCAST_COLLISION_LAYER;
	
	
	$Hitborder.add_child(left_wall);
	$Hitborder.add_child(right_wall);
	$Hitborder.add_child(top_wall);

	left_wall.global_position = $Hitborder/LeftWall.global_position + Vector2(bubble_radius, 0);
	right_wall.global_position = $Hitborder/RightWall.global_position + Vector2(-bubble_radius, 0);
	top_wall.global_position = $Hitborder/TopWall.global_position + Vector2(0, bubble_radius);
	

func add_next_row():
	row_offset_count += 1;
	
	for row in range(bubble_grid.size()):
		for col in range(bubble_grid[row].size()):
			if bubble_grid[row][col] == null:
				continue;
				
			lock_bobble_to_grid(bubble_grid[row][col], Vector2i(col, row + 1), false); 
	
	var new_row = [];
	
	for i in range(cell_count_horizontal - 1 if is_small_row(0) else cell_count_horizontal):
		new_row.append(lock_bobble_to_grid(bobble_set.pick_random().instantiate(), Vector2i(i, 0)));
	
	$SFX/NewRowSound.play();
	bubble_grid.insert(0, new_row);

func init_grid():
	var max_rows = ($BackgroundSprite.get_rect().size[1] * $BackgroundSprite.global_scale[1]) / row_height;
	# Increase max rows just to be extra safe in case of OOB or near OOB shots
	max_rows = int(max_rows * 1.2);

	for i in range(max_rows):
		
		var new_row = [];
		
		for j in range(cell_count_horizontal - 1 if is_small_row(i) else cell_count_horizontal):
			new_row.append(null); 

		bubble_grid.append(new_row);
	
	# Gives enough time for the previous add_child calls to execute
	$Timers/AddRowTimer.start();
	for i in range(initial_rows_count):
		await $Timers/AddRowTimer.timeout;
		add_next_row();
	$Timers/AddRowTimer.stop();


func set_next_bobble():
	next_bobble = bobble_set.pick_random().instantiate();
	$Tray/Gun/BobbleProp.copy_bobble_textures(next_bobble);

	$Tray/Gun/BobbleProp.set_food_scale(next_bobble.get_food_scale());
	$Tray/Gun/BobbleProp.set_shell_scale(next_bobble.get_shell_scale());


func fire_bobble():
	increment_flying_bobbles();
	$Tray/Gun/ShootSound.play();
	
	next_bobble.scale_bobble(bubble_radius);
	
	add_child(next_bobble);
	next_bobble.connect("impacted", handle_collision);
	next_bobble.global_position = $Tray/Gun/GunBase.global_position;
	next_bobble.set_velocity(Vector2(LAUNCH_SPEED_MAGNITUDE * sin(self.current_rotation), LAUNCH_SPEED_MAGNITUDE* -cos(self.current_rotation)));

	$Tray/Gun/BobbleProp.visible = false;
	shot_cooldown_finished = false;

func should_spawn_next_row() -> bool:
	return elapsed_seconds_for_new_row >= seconds_per_row;

func increment_flying_bobbles():
	flying_bobble_count += 1;

func decrement_flying_bobbles():
	flying_bobble_count -= 1;

func try_rotate_left(delta, speed_multiplier = 1.0):
	self.current_rotation = clampf(self.current_rotation - (delta * ROTATION_SPEED * speed_multiplier), -MAX_ROTATION_ABSOLUTE, MAX_ROTATION_ABSOLUTE);


func try_rotate_right(delta, speed_multiplier = 1.0):
	self.current_rotation = clampf(self.current_rotation + (delta * ROTATION_SPEED * speed_multiplier), -MAX_ROTATION_ABSOLUTE, MAX_ROTATION_ABSOLUTE);


func handle_collision(bobble):
	
	var impact_location = freeze_bobble_in_place(bobble);
	# Allows the static bobble to initialize completely
	$Timers/PopCooldown.start();
	await $Timers/PopCooldown.timeout;
	var pop_count_1 = pop_eligible_bobbles(impact_location);
	var pop_count_2 = pop_floating_bobbles();
	
	# Decrementing here rather than above prevents bugs where the row moves between PopCooldown.start() and timeout.
	decrement_flying_bobbles();
	$Timers/DelayBetweenPopTimer.start();
	
	for _i in range(pop_count_1 + pop_count_2):
		await $Timers/DelayBetweenPopTimer.timeout	
		$SFX/PopSound.pitch_scale = randf_range(MIN_POP_PITCH, MAX_POP_PITCH);
		$SFX/PopSound.play();
		
	$Timers/DelayBetweenPopTimer.stop();
	
	if should_fail():
		game_over.emit();

func dfs_for_floating_bobbles(grid : Array[Array], row : int, col : int):
	if grid[row][col] == null or grid[row][col].is_queued_for_deletion():
		return;

	grid[row][col] = null;
	
	# (Row, Col)
	var directions_from_big = [Vector2(1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(-1, -1) ];
	var directions_from_small = [Vector2(1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1), Vector2(-1, 0), Vector2(-1, 1)];

	var directions = directions_from_small if is_small_row(row) else directions_from_big;
		
	for direction in directions:
		var new_row = row + direction[0];
		var new_col = col + direction[1];  
	
		if new_row < 0 or new_row >= grid.size() or \
		   new_col < 0 or new_col >= grid[new_row].size() or \
		   grid[new_row][new_col] == null or \
		   grid[new_row][new_col].is_queued_for_deletion():
			continue;
		
		dfs_for_floating_bobbles(grid, new_row, new_col);	

func dfs_for_elligible_bobbles(grid : Array[Array], row : int, col : int, cur_type : String, cur_list : Array[Vector2]):
	if grid[row][col] == null:
		return;
	
	cur_list.append(Vector2(row, col));
	grid[row][col] = null;
	
	# (Row, Col)
	var directions_from_big = [Vector2(1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(-1, -1) ];
	var directions_from_small = [Vector2(1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1), Vector2(-1, 0), Vector2(-1, 1)];

	var directions = directions_from_small if is_small_row(row) else directions_from_big;
		
	for direction in directions:
		var new_row = row + direction[0];
		var new_col = col + direction[1];  
	
		if new_row < 0 or new_row >= grid.size() or \
		   new_col < 0 or new_col >= grid[new_row].size() or \
		   grid[new_row][new_col] == null or grid[new_row][new_col].bobble_type != cur_type:
			continue;
		
		dfs_for_elligible_bobbles(grid, new_row, new_col, cur_type, cur_list);
		
# returns number of bobbles popped
func pop_eligible_bobbles(impact_location : Vector2i) -> int:
	# Perform deep copy
	var grid_copy = bubble_grid.duplicate(true);
	var pop_count = 0;

	var eligible_bobbles : Array[Vector2]= [];	

	dfs_for_elligible_bobbles(grid_copy, impact_location[0], impact_location[1], grid_copy[impact_location[0]][impact_location[1]].bobble_type, eligible_bobbles);
	
	if eligible_bobbles.size() >= 3:
		pop_count += destroy_bobbles_at_coords(eligible_bobbles);
				
	
	return pop_count;
	

# returns number of bobbles popped
func pop_floating_bobbles() -> int:
	# Perform deep copy
	var grid_copy = bubble_grid.duplicate(true);
	for col in range(grid_copy[0].size()):
		dfs_for_floating_bobbles(grid_copy, 0 , col);
	
	var floating_bobbles : Array[Vector2]= [];	
	for row in range(grid_copy.size()):
		for col in range(grid_copy[row].size()):
			
			if grid_copy[row][col] == null:
				continue;
			
			floating_bobbles.append(Vector2(row, col));
		
	return destroy_bobbles_at_coords(floating_bobbles);

func destroy_bobbles_at_coords(coord_list : Array[Vector2]) -> int:
	var count_to_pop = 0;
	for coord in coord_list:
		if not bubble_grid[coord[0]][coord[1]].is_queued_for_deletion():
			spawn_props(bubble_grid[coord[0]][coord[1]]);
			bubble_grid[coord[0]][coord[1]].pop();
			count_to_pop += 1;
	
	return count_to_pop;

func spawn_props(bobble):
	var prop = food_prop_blueprint.instantiate();
	prop.scale_bobble(bubble_radius);
	prop.set_food_scale(bobble.get_food_scale());
	prop.copy_bobble_textures(bobble);
	add_child(prop);
	var impulse_vector = Vector2(randf_range(FOOD_PROP_X_VELOCITY_RANGE[0], FOOD_PROP_X_VELOCITY_RANGE[1]), randf_range(FOOD_PROP_Y_VELOCITY_RANGE[0], FOOD_PROP_Y_VELOCITY_RANGE[1]));
	prop.apply_central_impulse(impulse_vector);
	
	prop.set_global_position(bobble.global_position)


func freeze_bobble_in_place(bobble) -> Vector2i:
	var cell_indeces = get_nearest_empty_cell(bobble.global_position + Vector2(bubble_radius, bubble_radius));
	
	# For bobbles that lock to OOB, move them in bounds.
	if cell_indeces[1] < 0:
		cell_indeces = 0;
	if cell_indeces[0] < 0:
		cell_indeces[0] = 0;
	if cell_indeces[1] > bubble_grid.size() - 1:
		cell_indeces[1] = bubble_grid.size() - 1;
	if cell_indeces[0] > bubble_grid[cell_indeces[1]].size() - 1:
		cell_indeces[0] = bubble_grid[cell_indeces[1]].size() - 1;
	
	# For errant bobbles that want to occupy an already full location, destroy and report error. This  * shouldn't *  ever happen
	if bubble_grid[cell_indeces[1]][cell_indeces[0]] != null:
		bobble.queue_free();
		print("INVALID LANDING POSITION: %s, %s" % [cell_indeces[1], cell_indeces[0]]);
		return Vector2i(cell_indeces[1], cell_indeces[0]);
	
	bubble_grid[cell_indeces[1]][cell_indeces[0]] = lock_bobble_to_grid(bobble, cell_indeces);
	bobble.queue_free();
	return Vector2i(cell_indeces[1], cell_indeces[0]);
	
func lock_bobble_to_grid(bobble, indeces, replace_node = true) -> Node2D:

	var bobble_x : float;
	var bobble_y : float;
	
	if is_small_row(indeces[1]):
		bobble_x = bubble_radius * 2 * (indeces[0] + 1);
	else:
		bobble_x = bubble_radius + bubble_radius * 2 * (indeces[0]);
	
	bobble_y = indeces[1] * row_height;
	
	var x_pos = $Hitborder/LeftWall/CollisionShape2D.global_transform.origin.x + bobble_x;
	var y_pos = $Hitborder/TopWall/CollisionShape2D.global_position.y + \
				($Hitborder/TopWall/CollisionShape2D.shape.get_rect().size.y * $Hitborder/TopWall/CollisionShape2D.global_scale[1]) / 2 + \
				bubble_radius + bobble_y;
	
	var static_bobble;
	
	if replace_node:
		static_bobble = static_bobble_blueprint.instantiate();
		static_bobble.collision_layer |= RAYCAST_COLLISION_LAYER; 
		
		static_bobble.pixel_radius = bubble_radius;
		call_deferred("add_child", static_bobble);
		static_bobble.connect("added_to_tree", static_bobble.scale_bobble)
		static_bobble.connect("popped", parent_level.on_bobble_popped);
		
		static_bobble.set_food_texture(bobble.get_food_texture());
		static_bobble.set_shell_texture(bobble.get_shell_texture());


		const VISUAL_SCALE_INCREASE_FACTOR = 1.1;
		static_bobble.set_food_scale(VISUAL_SCALE_INCREASE_FACTOR * bobble.get_food_scale());
		static_bobble.set_shell_scale(VISUAL_SCALE_INCREASE_FACTOR * bobble.get_shell_scale());

		static_bobble.bobble_type = bobble.bobble_type;
		static_bobble.global_position = to_local(Vector2(x_pos, y_pos));
	else:
		static_bobble = bobble;
		static_bobble.global_position = Vector2(x_pos, y_pos);
	
	return static_bobble;

func print_grid(grid_to_print):
	for row in grid_to_print:
		print(row);

func get_y_grid_pos_for_kill_line() -> int:

	var bobble_game_length = $BackgroundSprite.get_rect().size[1] * global_scale[1];

	return round(((bobble_game_length - bubble_radius) / row_height) * KILL_LINE_PERCENTAGE);

func lock_kill_line_to_grid() -> void:
	var y_pos = $Hitborder/TopWall/CollisionShape2D.global_position.y + \
				($Hitborder/TopWall/CollisionShape2D.shape.get_rect().size.y * $Hitborder/TopWall/CollisionShape2D.global_scale[1]) / 2 + \
				bubble_radius + get_y_grid_pos_for_kill_line() * row_height;

	$KillLineSprite.global_position[1] = y_pos;


func get_nearest_empty_cell(center_of_bobble) -> Vector2i:
	var top_border_ypos = $Hitborder/TopWall/CollisionShape2D.global_transform.origin.y + $Hitborder/TopWall/CollisionShape2D.shape.get_rect().size[1];
	
	# Make origin y-coord relative to top barrier
	center_of_bobble[1] -= top_border_ypos;

	# Make origin x-coord relative to left border
	center_of_bobble[0] -= $Hitborder/LeftWall/CollisionShape2D.global_transform.origin.x
	
	var row_number : int = round((center_of_bobble[1] - 2 * bubble_radius) / row_height);
	var column_number : int;
	
	if is_small_row(row_number):
		column_number = round((center_of_bobble[0] - bubble_radius) / (2 * bubble_radius)) - 1;
	else:
		column_number = round((center_of_bobble[0])/ (2 * bubble_radius)) - 1;

	return Vector2(column_number,row_number);


# Only call in _physics_process()
func calculate_raycast_help_lines():
	help_lines = [];
	var direction = 1;
	var cast = individual_raycast($Tray/Gun/GunBase.global_position, direction, null);
	help_lines.append([cast[0], cast[1]]);

	while cast[2]:
		direction = -1 if direction == 1 else 1;
		cast = individual_raycast(cast[1], direction, cast[3]);
		if cast == null:
			break;
		
		help_lines.append([cast[0], cast[1]]);
	
func individual_raycast(start_pos, direction, last_collider_rid):
	var space_state = get_world_2d().direct_space_state;
	var ray_cast_start = start_pos;
	var ray_cast_direction = Vector2(direction * sin(self.current_rotation), -cos(self.current_rotation));
	
	# The large number here helps approximate the true line sufficiently. 
	# Without this the direction is correct, but the alignment is off.
	var query;
	if last_collider_rid == null:
		query = PhysicsRayQueryParameters2D.create(ray_cast_start, 100000000 * ray_cast_direction, RAYCAST_COLLISION_LAYER | BOBBLE_COLLISION_LAYER);
	else:
		query = PhysicsRayQueryParameters2D.create(ray_cast_start, 100000000 * ray_cast_direction, RAYCAST_COLLISION_LAYER | BOBBLE_COLLISION_LAYER, [last_collider_rid]);
	var result = space_state.intersect_ray(query);
	
	if result.size() == 0:
		return null;
	
	var should_cast_again = result.collider.is_in_group("rayflector");

	return [ray_cast_start, result.position, should_cast_again, result.rid];

func should_fail():
	for entry in bubble_grid[get_y_grid_pos_for_kill_line()]:
		if entry != null:
			return true;
	return false;

func is_small_row(row_number):
	return (row_number + row_offset_count) % 2 == 1;


func init_background_progress_bar_points():
	var points = PackedVector2Array();
	points.append(Vector2(0,0));
	for i in range(floor((1.02 * 2 * PI) / ANGLE_PER_POINT_RAD)):
		var angle = i * ANGLE_PER_POINT_RAD;
		var x_pos = cos(angle + CIRCLE_ANGLE_OFFSET) * PROGRESS_CIRCLE_RADIUS;
		var y_pos = sin(angle + CIRCLE_ANGLE_OFFSET) * PROGRESS_CIRCLE_RADIUS;	
		points.append(Vector2(x_pos, y_pos));
		
	$Tray/ProgressBar/ProgressPolygonBackground.polygon = points;
	$Tray/ProgressBar/ProgressPolygonDisabledShader.polygon = points;
	
func set_progress_to_next_row(percent):
	# Makes the circle animation look smoother, as it completes the circle before resetting
	percent += 0.02;
	
	var point_count = floor((percent * 2 * PI) / ANGLE_PER_POINT_RAD);
	
	if progress_circle_points.size() - 1 > point_count:
		var old_color = $Tray/ProgressBar/ProgressPolygonForeground.color;
		$Tray/ProgressBar/ProgressPolygonForeground.color = $Tray/ProgressBar/ProgressPolygonBackground.color;
		$Tray/ProgressBar/ProgressPolygonBackground.color = old_color;
		progress_circle_points.clear();
		percent = 0;
	
	if progress_circle_points.size() == 0:
		progress_circle_points.append(Vector2(0,0));
	
	# Subtract one to account for center point
	var current_point_count = progress_circle_points.size() - 1;
	
	for i in range(point_count - current_point_count):
		var angle = (current_point_count + i) * ANGLE_PER_POINT_RAD;
		var x_pos = cos(angle + CIRCLE_ANGLE_OFFSET) * PROGRESS_CIRCLE_RADIUS;
		var y_pos = sin(angle + CIRCLE_ANGLE_OFFSET) * PROGRESS_CIRCLE_RADIUS;	
		progress_circle_points.append(Vector2(x_pos, y_pos));
	
	$Tray/ProgressBar/ProgressPolygonForeground.polygon = progress_circle_points;

func init_exported_sprites():
	if background_sprite != null:
		var target_size = $BackgroundSprite.get_rect().size;
		$BackgroundSprite.texture = background_sprite;
		var real_size = background_sprite.get_size();
		$BackgroundSprite.scale = Vector2(target_size[0] / real_size[0], target_size[1] / real_size[1]);

	if tray_sprite != null:
		var target_size = $Tray/TraySprite.get_rect();
		$Tray/TraySprite.texture = tray_sprite;
		var real_size = $Tray/TraySprite.get_rect();
		$Tray/TraySprite.scale = Vector2(target_size[0] / real_size[0], target_size[1] / real_size[1]);
