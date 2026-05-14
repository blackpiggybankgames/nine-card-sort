shader_type canvas_item;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float maxChan = max(max(col.r, col.g), col.b);
	// 純粋な黒のみ透明にする（暗い茶色のボタン本体は透過しない）
	// min() でフォントアトラスの既存アルファ形状も保持する
	col.a = min(col.a, smoothstep(0.02, 0.1, maxChan));
	// * COLOR でGodotの頂点カラーを乗算（disabled状態の暗転を反映させる）
	COLOR = col * COLOR;
}
