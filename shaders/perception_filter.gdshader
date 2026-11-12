shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float afternoon_mix : hint_range(0.0, 1.0) = 0.0;
uniform float unfiltered_mix : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 src = texture(screen_tex, SCREEN_UV);
	vec3 col = src.rgb;

	// 1. Atos 1-2 (Manhã filtrada): leve realce cromático lúdico
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 morning_col = mix(vec3(luma), col, 1.18);
	morning_col *= vec3(1.02, 1.01, 0.98);

	// 2. Fim de tarde (Virar_Tarde): banho âmbar/alaranjado e sombras arroxeadas
	vec3 warm_tint = vec3(1.12, 0.86, 0.68);
	vec3 shadow_tint = vec3(0.78, 0.66, 0.88);
	vec3 afternoon_col = morning_col * mix(shadow_tint, warm_tint, clamp(luma * 1.35, 0.0, 1.0));

	vec3 filtered_col = mix(morning_col, afternoon_col, afternoon_mix);

	// 3. Ato 3 (Realidade sem filtro): cor drenada, contraste árido e vinheta fria
	vec3 gray = vec3(luma * 0.88 + 0.03);
	vec3 drained_col = mix(col, gray, 0.88);
	// Achata meios-tons e esfria as sombras
	drained_col = (drained_col - 0.5) * 0.92 + 0.46;
	drained_col *= vec3(0.93, 0.95, 0.98);

	vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;
	float vignette = clamp(1.0 - dot(centered_uv, centered_uv) * 0.22 * unfiltered_mix, 0.65, 1.0);

	vec3 final_col = mix(filtered_col, drained_col, unfiltered_mix) * vignette;
	COLOR = vec4(clamp(final_col, 0.0, 1.0), 1.0);
}
