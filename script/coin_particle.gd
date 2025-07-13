extends Control
class_name CoinParitcle 
@export var coin_texture: Texture2D
@export var coin_size: Vector2 = Vector2(48,48)
@export var coin_scatter_range: float = 40##扩散参数
@export var fly_duration: float = 0.5##飞行时间
@export var fly_delay_step: float = 0.03
# Called when the node enters the scene tree for the first time.
@export var target:Node2D

signal all_coins_collected

func emit_coin(pos:Vector2,coin_count: int,callback:Callable = Callable()):
	for i in coin_count:
		var coin = TextureRect.new()
		coin.texture = coin_texture
		coin.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		#coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.size = coin_size

		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(coin)
		
		#起始位置偏移
		var offset = Vector2(randf_range(-coin_scatter_range, coin_scatter_range),
							 randf_range(-coin_scatter_range, coin_scatter_range))
		coin.position = pos + offset
		
		await get_tree().create_timer(i * fly_delay_step).timeout

		var target_pos = target.get_global_position()
		var tween = create_tween()
		tween.tween_property(coin, "global_position", target_pos, fly_duration)\
			 .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		
		tween.tween_callback(Callable(coin, "queue_free"))
		
		# 如果是最后一个金币，触发回调
		if i == coin_count - 1 and callback.is_valid():
			tween.tween_callback(callback)

		# 最后一个金币发信号
		if i == coin_count - 1:
			tween.tween_callback(Callable(self, "emit_signal").bind("all_coins_collected"))
