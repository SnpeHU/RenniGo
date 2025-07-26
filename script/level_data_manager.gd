extends Node
##管理分数数据，分数计算,分数显示和游戏计时器
var hud: MainHUD

var box_count :int = 0
var score:int =0
#TODO 分数计算，完美，优秀。连击，倒计时
const BASE_GAMETIME :float = 30.0 ##每局基础时间
const BASE_COMBO_MULTIPLIER: float = 1.0 ##基础连击系数
var combo_count:int = 0
var combo_multiplier:float = BASE_COMBO_MULTIPLIER

@onready var game_timer:Node = $GameTimer
const SPEED_INCREASE_INTERVAL: float = 10.0  # 每X秒增加速度

func _ready() -> void:
	# 初始化计时器
	init_timer()

func connect_signal() -> void:
	# 连接游戏计时器百分比更新信号
	game_timer.percent_updated.connect(hud.set_bar_value)

#盒子发送分数信号时
func _on_box_score_emitted(new_top_box: Box, score_info: Dictionary) -> void:
	# 处理盒子分数信息
	print("分数等级：", score_info.level_text)
	print("本次盒子分数：", score_info.final_score)
	print("系数：", score_info.multiplier)

	#更新连击数，每十个连击增加一个倍率
	combo_count += 1
	if combo_count % 2 == 0:
		combo_multiplier += 0.1

	#更新分数
	box_count += 1
	var final_score = score_info.final_score * combo_multiplier
	print("连击数：", combo_count, "连击倍率：", combo_multiplier)
	print("最终分数：", final_score)
	score += final_score
	
	# 规则1：每次分数增加时，本次分数的百分之一作为增加的游戏时间
	var time_bonus = final_score * 0.01
	game_timer.add_time(time_bonus)
	print("本次时间奖励：", time_bonus)
	
	#TODO 更新HUD显示
	hud.set_count(box_count)

	#以top_box在摄像机上的位置为中心发射金币
	var screen_pos = new_top_box.get_global_transform_with_canvas().get_origin()
	var coin_count = score_info.final_score/20
	hud.coin_particle.emit_coin(screen_pos, coin_count,Callable(self, "on_coins_collected"))

#掉落时，清空连击数
func _on_box_falldown():
	if(GlobalMediator.level.current_state == Level.GameState.PLAYING):
		return
	
	# 清空连击数
	combo_count = 0
	combo_multiplier = BASE_COMBO_MULTIPLIER

	#TODO 更新HUD显示
	#hud.set_combo(combo_count, combo_multiplier)
	
func on_coins_collected()-> void:
	hud.set_score(score)
	
func init_timer() -> void:
	game_timer.init(BASE_GAMETIME, SPEED_INCREASE_INTERVAL)


func reset_data():
	#记录分数
	Data.high = score
	SaveLoad.save()
	
	# 重置游戏计时器
	game_timer.reset()

	box_count = 0
	score = 0
	combo_count = 0
	combo_multiplier = BASE_COMBO_MULTIPLIER

	hud.update_data(box_count,score)
