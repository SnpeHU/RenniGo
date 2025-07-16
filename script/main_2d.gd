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
@export var top_box:Box #最顶上的盒子，即需要与坠落的盒子判定的盒子，最初为Car
@onready var main_button:Button = $"../../UICanvasLayer/Control/MainButton"##控制游戏进程
signal update_top_box(top_box:Box)

#TODO 分数计算，完美，优秀。连击，倒计时
var box_count:int = 0
var score:int = 0
@onready var coin_emitter:Control = $HUD/CoinParticle ##金币粒子生成器

#游戏状态
enum GameState {
	READY,
	PLAYING,
	GAME_OVER 
}
var current_state: GameState # 初始状态为准备状态
@onready var hud:CanvasLayer = $HUD

# Called when the node enters the scene tree for the first time.
func _ready() -> void:		
	car_box = $Boxs/Car/RigidBody2D
	top_box = $Boxs/Car/RigidBody2D
	if(main_button):
		main_button.pressed.connect(_on_mainbutton_pressed)
	reset_to_ready()
	#初始化盒子出生的
	#init_respawnser()
	# 初始化为准备状态
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass



func _input(event: InputEvent) -> void:
	
	match current_state:
		GameState.READY:
			pass
			# 准备状态下，按任意键开始游戏
			#if event.is_action_pressed("put_down"):
				#start_game()
		GameState.PLAYING:
			# 游戏进行中的输入处理
			#if event.is_action_pressed("put_down"):
				#if box_respwanser and box_respwanser.box_hold:
					#box_respwanser.put_box_down()
			if event.is_action_pressed("reset_game"):
				game_over()
		GameState.GAME_OVER:
			pass
			# 结束状态下，按任意键重置游戏
			#if event.is_action_pressed("put_down"):
				#reset_to_ready()

	
	#按R键重置游戏
	#if event.is_action_pressed("reset_game"):
		#reset()

func _on_mainbutton_pressed() -> void:
	match current_state:
		GameState.READY:
			start_game()
		GameState.PLAYING:
			if box_respwanser and box_respwanser.box_hold:
				box_respwanser.put_box_down()
		GameState.GAME_OVER:
			reset_to_ready()


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
	#重置相机跟随点
	if camera_follow != null:
		camera_follow.global_position = Vector2.ZERO
	# 清空box
	if box_respwanser:
		box_respwanser.queue_free()
	reset()
	# 初始化游戏数据
	reset_data()
	#TODO 显示准备界面提示
	hud.show_center_container("点击开始游戏")  # 显示提示信息


# 游戏进行状态处理
func on_playing_state() -> void:

	# 初始化搬运器
	init_respawnser()
	
	#TODO 隐藏准备界面，显示游戏UI
	hud.clear_center_container()   # 隐藏提示信息

# 游戏结束状态处理
func on_game_over_state() -> void:
	# 停止所有游戏逻辑
	if box_respwanser:
		box_respwanser.set_process(false)
		box_respwanser.set_physics_process(false)	
	


	#TODO 显示游戏结束界面，显示分数等信息

# 检查游戏是否应该结束（可以根据需要调用）
func check_game_over_conditions() -> bool:
	# 这里可以添加游戏结束条件，比如：
	# - 盒子掉落太多次
	# - 达到最大高度
	# - 时间限制等
	return false

#TODO 清空数据
func reset_data():
	#记录分数
	Data	.high = score
	SaveLoad.save()
	box_count = 0
	score = 0
	$HUD.update_data(box_count,score)

# 开始游戏
func start_game() -> void:
	set_game_state(GameState.PLAYING)

# 游戏结束
func game_over() -> void:
	set_game_state(GameState.GAME_OVER)


# 重置到准备状态
func reset_to_ready() -> void:
	set_game_state(GameState.READY)	



# 当盒子成功下落时，更新top_box,更新摄像机跟随点,分数。。
func _on_box_stabilized(new_top_box: Box):
	top_box = new_top_box
	update_top_box.emit(top_box)
	#断开连接
	if(update_top_box.is_connected(top_box.set_top_box)):
		update_top_box.disconnect(top_box.set_top_box)
	
	#重设父节点为car内的boxs节点
	top_box.reparent($Boxs/Car/Boxs)
	
	box_respwanser.create_box_at_respawn_pos()
	box_respwanser.update_move_target(top_box.global_position)
	#更新分数
	box_count += 1
	score += new_top_box.score
	$HUD.set_count(box_count)
	#以top_box在摄像机上的位置为中心发射金币
	var screen_pos = top_box.get_global_transform_with_canvas().get_origin()
	var coin_count = new_top_box.score/20
	coin_emitter.emit_coin(screen_pos, coin_count,Callable(self, "on_coins_collected"))
		

	#更新相机追踪点
	if(top_box.global_position.y < camera_follow.global_position.y + follow_point_offset):
		camera_follow.global_position.y = top_box.global_position.y - follow_point_offset
	#print("Top box updated to: ", new_top_box.name)


func _on_box_falldown():
	if( current_state == GameState.PLAYING):
		if(box_respwanser):
			box_respwanser.create_box_at_respawn_pos()
		score -= 20
		$HUD.update_data(box_count,score)

func on_coins_collected():
	$HUD.set_score(score)

# 生成新盒子时，更新
func _on_create_box(new_box:Box):
	#current_box = new_current_box
	#设置当前盒子需要判定的盒子
	new_box.set_top_box(top_box)	
	#连接盒子的信号
	new_box.box_stabilized.connect(_on_box_stabilized)
	new_box.live_timer.timeout.connect(_on_box_falldown)
	
	update_top_box.connect(new_box.set_top_box)
	


func init_respawnser() -> void:
	if(box_respwanser != null):
		box_respwanser.queue_free()
		
	box_respwanser = box_respawnser_prefab.instantiate()
	add_child(box_respwanser)
	box_respwanser.global_position = respwanser_initial_pos
	box_respwanser.boxs_holder = boxs_node
	#box_respwanser.update_current_box.connect(_on_update_current_box)
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
	
	# 重置相机位置
	if camera_follow != null:
		camera_follow.global_position = Vector2.ZERO
	
	# 删除box_respwanser
	if box_respwanser:
		box_respwanser.queue_free()

	# 更新HUD显示
	if has_node("HUD"):
		$HUD.update_data(box_count, score)
	
	print("Game reset completed")
