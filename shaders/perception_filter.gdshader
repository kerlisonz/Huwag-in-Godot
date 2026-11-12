shader_type canvas_item;

// perception_filter.gdshader - Shader de Percepção e Estética VHS Controlada de Huwag
// Preserva a nitidez de pixel art com filter_nearest e escala 1080p sem borrões.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

// Parâmetros de iluminação e ato
uniform float afternoon_mix : hint_range(0.0, 1.0) = 0.0;
uniform float night_mix : hint_range(0.0, 1.0) = 0.0;
uniform float unfiltered_mix : hint_range(0.0, 1.0) = 0.0;

// Parâmetros de estética VHS (ajustáveis em tempo real por scripts e eventos)
uniform float vhs_scanline_alpha : hint_range(0.0, 1.0) = 0.08;
uniform float vhs_noise_intensity : hint_range(0.0, 1.0) = 0.04;
uniform float vhs_chromatic_aberration : hint_range(0.0, 1.0) = 0.0;
uniform float vhs_tracking_jitter : hint_range(0.0, 1.0) = 0.0;
uniform float vhs_crt_vignette : hint_range(0.0, 1.0) = 0.25;

float random_noise(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// 1. Instabilidade analógica sutil de rastreamento (tracking jitter)
	if (vhs_tracking_jitter > 0.001) {
		float line_noise = sin(uv.y * 300.0 + TIME * 15.0);
		if (line_noise > 0.96) {
			uv.x += (random_noise(vec2(TIME, uv.y)) - 0.5) * 0.015 * vhs_tracking_jitter;
		}
		// Desvio suave de quadro horizontal
		uv.x += sin(TIME * 6.0 + uv.y * 20.0) * 0.0015 * vhs_tracking_jitter;
	}

	// 2. Amostragem de cor com aberração cromática analógica controlada
	vec4 col;
	if (vhs_chromatic_aberration > 0.001) {
		float shift = 0.0025 * vhs_chromatic_aberration;
		float r = texture(screen_tex, vec2(uv.x + shift, uv.y)).r;
		float g = texture(screen_tex, uv).g;
		float b = texture(screen_tex, vec2(uv.x - shift, uv.y)).b;
		col = vec4(r, g, b, 1.0);
	} else {
		col = texture(screen_tex, uv);
	}

	vec3 c = col.rgb;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));

	// 3. Ato 1–2 (Manhã filtrada / Comprimidos): cores vivas e acolhedoras
	vec3 morning_col = mix(vec3(luma), c, 1.15) * vec3(1.02, 1.01, 0.98);

	// 4. Fim de tarde: tonalidade âmbar-dourada e sombras arroxeadas
	vec3 warm_tint = vec3(1.12, 0.86, 0.68);
	vec3 shadow_tint = vec3(0.78, 0.66, 0.88);
	vec3 afternoon_col = morning_col * mix(shadow_tint, warm_tint, clamp(luma * 1.35, 0.0, 1.0));

	vec3 filtered_col = mix(morning_col, afternoon_col, afternoon_mix);

	// 5. Noite: contraste azulado-frio tenso sem ocultar elementos essenciais de gameplay
	vec3 night_tint = vec3(0.68, 0.76, 0.95);
	vec3 night_col = filtered_col * night_tint * vec3(0.85, 0.88, 0.94);
	filtered_col = mix(filtered_col, night_col, night_mix);

	// 6. Ato 3 (Ato Sem Filtro): realidade crua, monocromática, desgastada e gasta
	vec3 gray = vec3(luma * 0.85 + 0.04);
	vec3 drained_col = mix(c, gray, 0.92);
	drained_col = (drained_col - 0.5) * 0.88 + 0.44; // Reduz gama e meio-tom
	drained_col *= vec3(0.92, 0.95, 0.98);

	vec3 base_col = mix(filtered_col, drained_col, unfiltered_mix);

	// 7. Efeito Scanlines CRT / VHS nítido (não desfoca as texturas)
	if (vhs_scanline_alpha > 0.001) {
		float scanline = sin(uv.y * 360.0 * PI) * 0.5 + 0.5;
		base_col *= (1.0 - scanline * vhs_scanline_alpha);
	}

	// 8. Granulação estática de fita VHS
	if (vhs_noise_intensity > 0.001) {
		float noise = (random_noise(uv + vec2(TIME * 0.12, TIME * 0.35)) - 0.5);
		base_col += noise * vhs_noise_intensity;
	}

	// 9. Vinheta suave de tela CRT
	vec2 center_uv = uv * 2.0 - 1.0;
	float vignette = clamp(1.0 - dot(center_uv, center_uv) * 0.28 * vhs_crt_vignette, 0.60, 1.0);
	base_col *= vignette;

	COLOR = vec4(clamp(base_col, 0.0, 1.0), 1.0);
}
