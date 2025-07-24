extends CanvasLayer

#signal start_game
class_name MainHUD
@onready var count:Label = $UI/Left_top/HBoxContainer2/Count
@onready var score:Label = $UI/Left_top/HBoxContainer/Score
@onready var center_container:Control = $UI/CenterHint
@onready var hint:Label = $UI/CenterHint/Hint_text
@onready var high_score:Label = $UI/CenterHint/HBoxContainer/HighScore
@onready var game_timer_bar:Control =$UI/TextureProgressBar #$UI/GameProgressBar
@onready var coin_particle:CoinParitcle = $CoinParticle


var tween: Tween
var pulse_tween: Tween
var fade_duration: float = 0.5  # 渐变持续时间
var pulse_duration: float = 5.0  # 脉冲周期
var pulse_min_alpha: float = 0.3  # 脉冲最小透明度
var pulse_max_alpha: float = 1.0  # 脉冲最大透明度

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalMediator.HUD = self
	visible = true
	tween = create_tween()
	tween.kill()  # 初始化时停止tween
	pulse_tween = create_tween()
	pulse_tween.kill()  # 初始化时停止脉冲tween


func update_data(count_value, score_value):
	set_count(count_value)
	set_score(score_value)
	set_high_score()


func set_count(count_value):
	count.text = "%d" % count_value

func set_score(score_value):
	score.text = "%d" % score_value
	set_high_score()

func set_high_score():
	high_score.text = "%d" % Data.high
	
func set_bar_value(_value:float):
	game_timer_bar.value = _value





# 显示hint并播放渐入动画
func show_with_fade(node:Control):
	node.modulate.a = 0.0  # 设置初始透明度为0
	node.visible = true
	
	# 停止之前的动画
	stop_all_animations()
	
	# 创建渐入动画
	tween = create_tween()
	tween.tween_property(node, "modulate:a", pulse_max_alpha, fade_duration)
	# 渐入完成后开始脉冲效果
	tween.tween_callback(func(): start_pulse_effect(node))

# 隐藏hint并播放渐出动画
func hide_with_fade(node:Control):
	if not node.visible:
		return
	
	# 停止所有动画
	stop_all_animations()
	
	# 创建渐出动画
	tween = create_tween()
	tween.tween_property(node, "modulate:a", 0.0, fade_duration)
	# 动画完成后隐藏节点
	tween.tween_callback(func(): node.visible = false)

# 停止所有hint相关的动画
func stop_all_animations():
	if tween:
		tween.kill()
	if pulse_tween:
		pulse_tween.kill()

# 开始脉冲效果
func start_pulse_effect(node:Control):
	if not node.visible:
		return
	
	pulse_tween = create_tween()
	pulse_tween.set_loops()  # 设置为循环动画
	
	# 创建脉冲动画：从最大透明度到最小透明度，再回到最大透明度
	pulse_tween.tween_property(node, "modulate:a", pulse_min_alpha, pulse_duration / 2)
	pulse_tween.tween_property(node, "modulate:a", pulse_max_alpha, pulse_duration / 2)



# 清除hint（带渐变效果）
func clear_center_container():
	hide_with_fade(center_container)

# 设置hint文本并显示（带脉冲效果）
func show_center_container(text: String):
	hint.text = text
	show_with_fade(center_container)

# 立即显示hint（无动画）
func show_hint_immediate(text: String = ""):
	if text != "":
		hint.text = text
	
	stop_all_animations()
	hint.modulate.a = pulse_max_alpha
	hint.visible = true
	#start_pulse_effect()
	
	
