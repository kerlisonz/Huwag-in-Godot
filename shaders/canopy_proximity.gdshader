shader_type canvas_item;

// Shader para copas de árvores, coqueiros e beirais: combina balanço pixel-snapped
// com atenuação suave quando o jogador passa atrás/abaixo da copa em Y-sort.

uniform float wind_strength : hint_range(0.0, 4.0) = 1.1;
uniform float wind_speed : hint_range(0.1, 6.0) = 1.5;
uniform float phase_offset : hint_range(0.0, 6.283) = 0.0;
uniform float vertical_anchor : hint_range(0.0, 1.0) = 0.85;
uniform float distortion_jitter : hint_range(0.0, 3.0) = 0.0;

uniform bool proximity_fade_enabled = false;
uniform vec2 player_world_pos = vec2(0.0, 0.0);
uniform float fade_radius : hint_range(8.0, 96.0) = 32.0;
uniform float min_alpha : hint_range(0.15, 1.0) = 0.42;

varying vec2 v_world_pos;

void vertex() {
	float h_weight = clamp((vertical_anchor - UV.y) / max(0.05, vertical_anchor), 0.0, 1.0);
	float wave = sin(TIME * wind_speed + phase_offset + UV.y * 4.0) * wind_strength;
	float jitter = sin(TIME * 19.0 + phase_offset * 3.0) * distortion_jitter * 0.5;
	VERTEX.x += round((wave + jitter) * h_weight);
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float alpha_mult = 1.0;
	if (proximity_fade_enabled && tex.a > 0.02) {
		float dist = distance(v_world_pos, player_world_pos);
		float t = smoothstep(fade_radius * 0.35, fade_radius, dist);
		alpha_mult = mix(min_alpha, 1.0, t);
	}
	COLOR = vec4(tex.rgb, tex.a * alpha_mult);
}
