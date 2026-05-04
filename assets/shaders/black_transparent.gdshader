shader_type canvas_item;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	// 暗いピクセルほど透明にする（黒→完全透過、明るい色→不透明）
	col.a = smoothstep(0.05, 0.25, lum);
	COLOR = col;
}
