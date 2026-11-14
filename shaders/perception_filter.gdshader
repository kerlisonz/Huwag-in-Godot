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

// Artefatos adicionais de fita (usados em menus e telas de "gravação")
uniform float vhs_tracking_band : hint_range(0.0, 1.0) = 0.0; // banda de rastreamento rolando
uniform float vhs_head_switch : hint_range(0.0, 1.0) = 0.0; // ruído de comutação de cabeça na base
uniform float vhs_dropout : hint_range(0.0, 1.0) = 0.0;     // linhas de dropout de fita desgastada
uniform float vhs_tear : hint_range(0.0, 1.0) = 0.0;        // rasgo horizontal de fita (evento de glitch)

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

	// 1b. Banda de rastreamento VHS rolando verticalmente pela tela
	if (vhs_tracking_band > 0.001) {
		float band_center = fract(TIME * 0.07);
		float bd = abs(uv.y - band_center);
		bd = min(bd, 1.0 - bd);
		float band = smoothstep(0.08, 0.0, bd);
		float amp = band * vhs_tracking_band;
		uv.x += (random_noise(vec2(floor(uv.y * 140.0), floor(TIME * 24.0))) - 0.5) * 0.06 * amp;
		uv.y += sin(uv.x * 30.0 + TIME * 8.0) * 0.004 * amp;
	}

	// 1c. Rasgo horizontal de fita (glitch): blocos inteiros deslocados lateralmente
	if (vhs_tear > 0.001) {
		float block = floor(uv.y * 26.0);
		float tframe = floor(TIME * 20.0);
		float tr = random_noise(vec2(block, tframe));
		if (tr > 1.0 - vhs_tear * 0.35) {
			uv.x += (random_noise(vec2(block + 3.1, tframe)) - 0.5) * 0.09 * vhs_tear;
		}
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

	// 6b. Ruído de comutação de cabeça na base da fita (head-switching noise)
	if (vhs_head_switch > 0.001) {
		float hb = smoothstep(0.90, 1.0, uv.y);
		float hn = random_noise(vec2(uv.x * 220.0, floor(TIME * 40.0)));
		base_col = mix(base_col, vec3(hn * 0.9 + 0.05), hb * vhs_head_switch);
	}

	// 6c. Dropouts aleatórios: linhas brilhantes de fita gasta
	if (vhs_dropout > 0.001) {
		float row = floor(uv.y * 180.0);
		float dr = random_noise(vec2(row, floor(TIME * 18.0)));
		if (dr > 1.0 - 0.04 * vhs_dropout) {
			base_col += vec3(0.55) * vhs_dropout;
		}
	}

	// 6d. Estática de rasgo durante o glitch da fita
	if (vhs_tear > 0.001) {
		base_col += (random_noise(uv + vec2(TIME * 13.0, TIME * 7.0)) - 0.5) * 0.2 * vhs_tear;
	}

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
