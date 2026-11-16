shader_type canvas_item;

uniform float wind_speed : hint_range(0.1, 6.0) = 1.8;
uniform float wind_strength : hint_range(0.0, 6.0) = 1.6;
uniform float phase_offset : hint_range(0.0, 6.28318) = 0.0;
uniform float vertical_anchor : hint_range(0.2, 1.0) = 0.82;
uniform float distortion_jitter : hint_range(0.0, 2.0) = 0.0;

void vertex() {
	float sway_mask = clamp((vertical_anchor - UV.y) / max(vertical_anchor, 0.001), 0.0, 1.0);
	float wave = sin(TIME * wind_speed + phase_offset + UV.y * 2.5) * wind_strength;
	if (distortion_jitter > 0.001) {
		wave += cos(TIME * 11.0 + phase_offset * 3.0) * distortion_jitter;
	}
	VERTEX.x += round(wave * sway_mask);
}
