class_name Level
extends Node2D

@export var box_prefab: PackedScene  = preload("res://scene2d/box2D.tscn")#盒子预制体
@export var box_respawnser_prefab:PackedScene  = preload("res://scene2d/box_respawnser.tscn")

@onready var boxs_node: Node2D = $Boxs; #存放盒子的节点
var box_respwanser: Node2D#搬运猫
@export var respwanser_initial_pos: Vector2#

#摄像机
@export var camera: PhantomCamera2D
@export var camera_follow :Node2D ##相机跟随节点
@export var follow_point_offset:float  = 200##与顶部盒子y坐标的偏移量

#游戏逻辑
@onready var car:Node2D = $Boxs/Car
@export var car_box: Box
@export var top_box:Box #最顶上的盒子，即需要与坠落的盒子判定的盒子，最初为Car,暂时仅用于更新跟踪点
@onready var main_button:Button = $"../../UICanvasLayer/Control/MainButton"##控制游戏进程

@onready var level_data_manager: Node = $LevlDataManager
@onready var game_timer:GameTimer = $LevlDataManager/GameTimer
@onready var hud : MainHUD = $HUD

#游戏状态
enum GameState {
	READY,
	PLAYING,
	GAME_OVER 
}
var current_state: GameState # 初始状态为准备状态

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	GlobalMediator.level = self
	level_data_manager.hud = hud
	level_data_manager.init_timer()
	car_box = $Boxs/Car/RigidBody2D
	top_box = $Boxs/Car/RigidBody2D
	if(main_button):
		main_button.pressed.connect(_on_mainbutton_pressed)
	if(level_data_manager):
		level_data_manager.connect_signal()
	# 初始化为准备状态
	reset_to_ready()
	
		

func _input(event: InputEvent) -> void:
	
	match current_state:
		GameState.READY:
			pass
			# 准备状态下，按任意键开始游戏
			#if event.is_action_pressed("put_down"):
				#start_game()
		GameState.PLAYING:
			# 游戏进行中的输入处理
			if event.is_action_pressed("reset_game"):
				game_over()
		GameState.GAME_OVER:
			pass
			# 结束状态下，按任意键重置游戏
			#if event.is_action_pressed("put_down"):
				#reset_to_ready()

func _on_mainbutton_pressed() -> void:
	match current_state:
		GameState.READY:
			start_game()
		GameState.PLAYING:
			if box_respwanser:
				box_respwanser.put_box_down()
		GameState.GAME_OVER:
			reset_to_ready()

# 开始游戏
func start_game() -> void:
	set_game_state(GameState.PLAYING)

# 游戏结束
func game_over() -> void:
	set_game_state(GameState.GAME_OVER)

# 重置到准备状态
func reset_to_ready() -> void:
	set_game_state(GameState.READY)	

# 设置游戏状态
func set_game_state(new_state: GameState) -> void:
	var old_state = current_state
	current_state = new_state
	
	match current_state:
		GameState.READY:
			on_ready_state()
		GameState.PLAYING:
			on_playing_state()
		GameState.GAME_OVER:
			on_game_over_state()
	
	print("Game state changed from ", GameState.keys()[old_state], " to ", GameState.keys()[current_state])

# 准备状态处理
func on_ready_state() -> void:
	# 重置场景中对象
	reset()
	# 初始化游戏数据
	level_data_manager.reset_data()
	#TODO 显示准备界面提示
	hud.show_center_container("点击开始游戏")  # 显示提示信息


# 游戏进行状态处理
func on_playing_state() -> void:
	# 初始化搬运器
	init_respawnser()
	
	# 开始计时
	game_timer.start()
	
	#隐藏准备界面，显示游戏UI
	hud.clear_center_container()   # 隐藏提示信息

# 游戏结束状态处理
func on_game_over_state() -> void:
	# 停止所有游戏逻辑
	if box_respwanser:
		box_respwanser.set_process(false)
		box_respwanser.set_physics_process(false)	
	
	# 停止游戏计时器
	game_timer.stop()

	#TODO 显示游戏结束界面，显示分数等信息

# 当盒子成功下落时，更新top_box,更新摄像机跟随点,分数。。
func _on_box_stabilized(new_top_box: Box):
	top_box = new_top_box

	#重设父节点为car内的boxs节点
	top_box.reparent($Boxs/Car/Boxs)
	
	#box_respwanser.create_box_at_respawn_pos()
	box_respwanser.update_move_target(top_box.global_position)

	#更新相机追踪点
	if(top_box.global_position.y < camera_follow.global_position.y + follow_point_offset):
		camera_follow.global_position.y = top_box.global_position.y - follow_point_offset
	#print("Top box updated to: ", new_top_box.name)


# 生成新盒子时，更新
func _on_create_box(new_box:Box):
	#连接盒子的信号
	new_box.box_stabilized.connect(_on_box_stabilized)
	new_box.box_fall_down.connect(level_data_manager._on_box_falldown)
	new_box.box_score_emitted.connect(level_data_manager._on_box_score_emitted)
	

func init_respawnser() -> void:
	if(box_respwanser != null):
		box_respwanser.queue_free()
		
	box_respwanser = box_respawnser_prefab.instantiate()
	add_child(box_respwanser)
	box_respwanser.global_position = respwanser_initial_pos
	box_respwanser.boxs_holder = boxs_node
	box_respwanser.create_box.connect(_on_create_box)
	box_respwanser.create_box_at_respawn_pos()
	box_respwanser.update_move_target(car.global_position)

#重置游戏状态
func reset()->void:	
	# 清理car上的盒子）
	car.clear_box()

	# 重置top_box为初始状态（car）
	if car_box != null:
		top_box = car_box
		top_box.is_top_box = true
	
	# 重置相机位置
	if camera_follow != null:
		camera_follow.global_position = Vector2.ZERO
	
	# 删除box_respwanser
	if box_respwanser:
		box_respwanser.queue_free()

	print("Game reset completed")
