#sounds from opengameart.org under public domain licence
extends Node

@export var snake_scene : PackedScene

#game variables
var score : int
var potions : int
var game_started : bool = false

#grid variables
var cells : int = 20
var cell_size : int = 50

#food variables
var food_pos : Vector2
var regen_food : bool = true

#snake variables
var old_data : Array
var snake_data : Array
var snake : Array

#movement variables
var start_pos = Vector2(9, 9)
var up = Vector2(0, -1)
var down = Vector2(0, 1)
var left = Vector2(-1, 0)
var right = Vector2(1, 0)
var move_direction : Vector2
var can_move: bool
var invincible_count: int

# Called when the node enters the scene tree for the first time.
func _ready():
	new_game()
	
func new_game():
	get_tree().paused = false
	get_tree().call_group("segments", "queue_free")
	$GameOverMenu.hide()
	score = 0
	$Hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
	potions = 3
	$Hud.get_node("PotionsLabel").text = "POTIONS: " + str(potions)
	move_direction = up
	can_move = true
	invincible_count = 0 
	generate_snake()
	move_food()
	
func generate_snake():
	old_data.clear()
	snake_data.clear()
	snake.clear()
	#starting with the start_pos, create tail segments vertically down
	for i in range(10):
		add_segment(start_pos + Vector2(0, i))

func get_colour_style():
	# Choose snake colour
	var style:StyleBoxFlat = StyleBoxFlat.new()
	if invincible_count > 0:
		if invincible_count % 2 == 0:
			style.bg_color = Color.CORAL
			style.bg_color.a = 0.6
		else:
			style.bg_color = Color.CRIMSON
			style.bg_color.a = 0.6
	else:
		style.bg_color = Color.CHARTREUSE
	# 
	return style

func add_segment(pos):
	snake_data.append(pos)
	var SnakeSegment = snake_scene.instantiate()
	SnakeSegment.position = (pos * cell_size) + Vector2(0, cell_size)
	SnakeSegment.add_theme_stylebox_override("panel", get_colour_style() )
	snake.append(SnakeSegment)
	add_child(SnakeSegment)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_snake()
	
func move_snake():
	if can_move:
		#update movement from keypresses
		if Input.is_action_just_pressed("move_down") and move_direction != up:
			move_direction = down
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_up") and move_direction != down:
			move_direction = up
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_left") and move_direction != right:
			move_direction = left
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_right") and move_direction != left:
			move_direction = right
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed(" become_invincible") and game_started == true:
			if potions >0: 
				potions = potions-1
				invincible_count = 15
				$Hud.get_node("PotionsLabel").text = "POTIONS: " + str(potions)
				$Hud.get_node("AudioStreamPlayer").play()

func start_game():
	game_started = true
	$MoveTimer.start()


func _on_move_timer_timeout():
	#allow snake movement
	can_move = true

	# Choose snake colour
	var style:StyleBoxFlat = get_colour_style()

	#use the snake's previous position to move the segments
	old_data = [] + snake_data
	snake_data[0] += move_direction
	if invincible_count>0:
		if snake_data[0].x < 0:
			snake_data[0].x = cells - 1
		if snake_data[0].x > cells - 1:
			snake_data[0].x = 0
		if snake_data[0].y <0:
			snake_data[0].y = cells -1
		if snake_data[0].y > cells -1:
			snake_data[0].y=0
		
	for i in range(len(snake_data)):
		#move all the segments along by one
		if i > 0:
			snake_data[i] = old_data[i - 1]
		snake[i].position = (snake_data[i] * cell_size) + Vector2(0, cell_size)
		snake[i].add_theme_stylebox_override("panel", style)
	# snake[0].position = Vector2(-10,-10)

	if invincible_count > 0:
		invincible_count = invincible_count - 1

	check_out_of_bounds()
	if invincible_count == 0:
		check_self_eaten()
	check_food_eaten()
	
func check_out_of_bounds():
	if snake_data[0].x < 0 or snake_data[0].x > cells - 1 or snake_data[0].y < 0 or snake_data[0].y > cells - 1:
		end_game()
		
func check_self_eaten():
	for i in range(1, len(snake_data)):
		if snake_data[0] == snake_data[i]:
			end_game()
			
func check_food_eaten():
	#if snake eats the food, add a segment and move the food
	if snake_data[0] == food_pos:
		score += 1
		$Hud.get_node("AudioStreamPlayerFood").play()
		$Hud.get_node("ScoreLabel").text = "SCORE: " + str(score)
		add_segment(old_data[-1])
		move_food()
	
func move_food():
	while regen_food:
		regen_food = false
		food_pos = Vector2(randi_range(0, cells - 1), randi_range(0, cells - 1))
		for i in snake_data:
			if food_pos == i:
				regen_food = true
	$Food.position = (food_pos * cell_size)+ Vector2(0, cell_size)
	regen_food = true

func end_game():
	$GameOverMenu.show()
	$MoveTimer.stop()
	game_started = false
	get_tree().paused = true


func _on_game_over_menu_restart():
	new_game()
