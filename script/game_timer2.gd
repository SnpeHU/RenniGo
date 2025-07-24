extends Node
class_name GameTimer

# 倒计时速度相关常量
const SPEED_INCREASE_RATE: float = 0.1       # 每次增加10%的速度
const MAX_SPEED_MULTIPLIER: float = 3.0      # 最大速度倍率（3倍速）

# 时间变量
var speed_increase_interval : float          # 每X秒增加速度
var speed_multiplier: float = 1.0            # 当前速度倍率
var elapsed_time: float = 0.0                # 已经过的总时间
var last_speed_increase_time: float = 0.0    # 上次增加速度的时间

# 点数变量
var base_wait_points: float = 10.0              # 基础等待时间点数
var remaining_points: float = 0.0              # 剩余时间点数
var one_shot: bool = true                      # 是否为单次计时器
var is_stopped: bool = true                    # 计时器是否停止

signal percent_updated(percent: float)  # 百分比更新信号


func _process(delta):
	if not is_stopped:
		# 更新已过时间
		elapsed_time += delta
		# 检查是否需要增加速度
		if elapsed_time - last_speed_increase_time >= speed_increase_interval:
			increase_countdown_speed()
			last_speed_increase_time = elapsed_time
		# 更新剩余点数
		remaining_points -= delta * speed_multiplier
		if remaining_points <= 0:
			on_timeout()
		# 更新百分比
		var percent: float = (remaining_points / base_wait_points) * 100
		emit_signal("percent_updated", percent)

func init(base_wait_points: float, speed_increase_interval: float) -> void:
	self.base_wait_points = base_wait_points
	self.speed_increase_interval = speed_increase_interval
	self.reset()


func add_time(bonus_points: float) -> void:
	remaining_points += bonus_points

# 增加倒计时速度
func increase_countdown_speed() -> void:
	if speed_multiplier < MAX_SPEED_MULTIPLIER:
		speed_multiplier = min(speed_multiplier * (1.0 + SPEED_INCREASE_RATE), MAX_SPEED_MULTIPLIER)
		print("倒计时速度增加：", "->", speed_multiplier)


func start():
	is_stopped = false
	remaining_points = base_wait_points
	one_shot = true

func stop():
	is_stopped = true 

func reset() -> void:
	stop()
	remaining_points = base_wait_points
	speed_multiplier = 1.0


func on_timeout() -> void:
	is_stopped = true
	# 触发游戏结束状态
	if GlobalMediator.level:
		GlobalMediator.level.set_game_state(Level.GameState.GAME_OVER)
