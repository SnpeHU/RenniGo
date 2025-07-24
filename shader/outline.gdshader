shader_type canvas_item;
uniform float outline_width = 5;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform vec4 outline_color : source_color= vec4(0,0,0,1);
uniform bool enable_outline = false;

//pulse_speed: 控制脉动速度，值越大变化越快
//min_alpha: 透明度的最小值
//max_alpha: 透明度的最大值
uniform float pulse_speed : hint_range(0.1, 10.0) = 1.5;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.0;
uniform float max_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = UV;
	vec4 original_color = texture(TEXTURE, UV);
	if(enable_outline) {
	vec2 uv_up = uv + vec2(0,TEXTURE_PIXEL_SIZE.y ) * outline_width;
	vec2 uv_down = uv - vec2(0,TEXTURE_PIXEL_SIZE.y ) * outline_width;
	vec2 uv_left = uv - vec2(TEXTURE_PIXEL_SIZE.x,0) * outline_width;
	vec2 uv_right = uv + vec2(TEXTURE_PIXEL_SIZE.x,0) * outline_width;

	vec4 color_up = texture(TEXTURE,uv_up);
	vec4 color_down = texture(TEXTURE,uv_down);
	vec4 color_left = texture(TEXTURE,uv_left);
	vec4 color_right = texture(TEXTURE,uv_right);

	vec4 outline = color_up + color_down + color_left + color_right;
	outline.rgb = outline_color.rgb;

	//修改描边颜色的透明度，保持平滑效果
	float time_alpha = mix(min_alpha, max_alpha, (sin(TIME * pulse_speed) + 1.0) * 0.5);

	//float heartbeat = abs(sin(TIME * pulse_speed * 2.0)) * abs(cos(TIME * pulse_speed));
	//float time_alpha = mix(min_alpha, max_alpha, heartbeat);
    outline.a = outline_color.a * time_alpha * clamp(outline.a, 0.0, 1.0);
	COLOR = mix(outline, original_color, original_color.a);
	}else{
		original_color.a *= alpha;
		COLOR = original_color;
	}

}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
