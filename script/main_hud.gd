extends CanvasLayer

signal start_game

@onready var count:Label = $UI/VBoxContainer/HBoxContainer2/Count
@onready var score:Label = $UI/VBoxContainer/HBoxContainer/Score
@onready var hint:Label = $UI/Hint

var hint_tween: Tween
var hint_pulse_tween: Tween
var hint_fade_duration: float = 0.5  # 渐变持续时间
var hint_pulse_duration: float = 2.0  # 脉冲周期
var hint_pulse_min_alpha: float = 0.3  # 脉冲最小透明度
var hint_pulse_max_alpha: float = 1.0  # 脉冲最大透明度

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hint_tween = create_tween()
	hint_tween.kill()  # 初始化时停止tween
	hint_pulse_tween = create_tween()
	hint_pulse_tween.kill()  # 初始化时停止脉冲tween

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func update_data(count_value, score_value):
	set_count(count_value)
	set_score(score_value)

func set_count(count_value):
	count.text = "%d" % count_value

func set_score(score_value):
	score.text = "%d" % score_value

# 显示hint并播放渐入动画
func show_hint_with_fade():
	hint.modulate.a = 0.0  # 设置初始透明度为0
	hint.visible = true
	
	# 停止之前的动画
	stop_all_hint_animations()
	
	# 创建渐入动画
	hint_tween = create_tween()
	hint_tween.tween_property(hint, "modulate:a", hint_pulse_max_alpha, hint_fade_duration)
	# 渐入完成后开始脉冲效果
	hint_tween.tween_callback(start_hint_pulse_effect)

# 隐藏hint并播放渐出动画
func hide_hint_with_fade():
	if not hint.visible:
		return
	
	# 停止所有动画
	stop_all_hint_animations()
	
	# 创建渐出动画
	hint_tween = create_tween()
	hint_tween.tween_property(hint, "modulate:a", 0.0, hint_fade_duration)
	# 动画完成后隐藏节点
	hint_tween.tween_callback(func(): hint.visible = false)

# 停止所有hint相关的动画
func stop_all_hint_animations():
	if hint_tween:
		hint_tween.kill()
	if hint_pulse_tween:
		hint_pulse_tween.kill()

# 开始脉冲效果
func start_hint_pulse_effect():
	if not hint.visible:
		return
	
	hint_pulse_tween = create_tween()
	hint_pulse_tween.set_loops()  # 设置为循环动画
	
	# 创建脉冲动画：从最大透明度到最小透明度，再回到最大透明度
	hint_pulse_tween.tween_property(hint, "modulate:a", hint_pulse_min_alpha, hint_pulse_duration / 2)
	hint_pulse_tween.tween_property(hint, "modulate:a", hint_pulse_max_alpha, hint_pulse_duration / 2)



# 清除hint（带渐变效果）
func clear_hint():
	hide_hint_with_fade()

# 设置hint文本并显示（带脉冲效果）
func show_hint(text: String):
	hint.text = text
	show_hint_with_fade()

# 立即显示hint（无动画）
func show_hint_immediate(text: String = ""):
	if text != "":
		hint.text = text
	
	stop_all_hint_animations()
	hint.modulate.a = hint_pulse_max_alpha
	hint.visible = true
	start_hint_pulse_effect()
	
	
