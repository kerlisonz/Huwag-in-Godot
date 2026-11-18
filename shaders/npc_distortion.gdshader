shader_type canvas_item;

// Shader autoral de Distorção do Ato 2 (compatível com GL Compatibility e sheets 10x4).
// Aplica esticamento vertical inquietante, fatias horizontais de glitch VHS,
// aberração cromática vermelha e descoloração para tons carmesim e fuligem.

uniform float distortion_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float hostile_boost : hint_range(0.0, 1.0) = 0.0;
uniform float phase_seed : hint_range(0.0, 10.0) = 0.0;
uniform vec4 dark_red_tint : source_color = vec4(0.88, 0.18, 0.22, 1.0);

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void vertex() {
	if (distortion_intensity > 0.01) {
		float t = TIME * (3.6 + hostile_boost * 4.2) + phase_seed * 2.3;
		// Ancoragem próxima aos pés (+24px na célula 48x48) -> esticamento vertical sombrio no topo
		float top_factor = clamp((24.0 - VERTEX.y) / 48.0, 0.0, 1.0);
		float stretch_wave = 0.5 + 0.5 * sin(t * 1.45);
		float stretch_px = distortion_intensity * (2.6 + hostile_boost * 3.8) * (0.55 + 0.45 * stretch_wave);
		VERTEX.y -= top_factor * stretch_px;

		// Espasmo / tremor horizontal repentino em picos de glitch
		float spasm_gate = smoothstep(0.74 - hostile_boost * 0.18, 0.98, sin(t * 2.9 + phase_seed));
		float twitch_x = (hash12(vec2(floor(TIME * 18.0), phase_seed)) - 0.5) * 3.6;
		VERTEX.x += twitch_x * distortion_intensity * (0.35 + spasm_gate * 1.25) * top_factor;
		VERTEX.x *= 1.0 - distortion_intensity * 0.06 * top_factor;
	}
}

void fragment() {
	vec4 base_sample = texture(TEXTURE, UV);
	if (distortion_intensity <= 0.01) {
		COLOR = base_sample * COLOR;
	} else {
		// Limita o deslocamento UV para dentro da célula ativa (grade 10x4) evitando vazamento entre quadros
		float cell_col = floor(clamp(UV.x, 0.0, 0.9999) * 10.0);
		float u_min = cell_col * 0.1 + TEXTURE_PIXEL_SIZE.x * 0.5;
		float u_max = (cell_col + 1.0) * 0.1 - TEXTURE_PIXEL_SIZE.x * 0.5;

		float local_v = fract(UV.y * 4.0);
		float slice_id = floor(local_v * 24.0);
		float tick = floor(TIME * (10.0 + hostile_boost * 9.0));
		float slice_rnd = hash12(vec2(slice_id + phase_seed, tick));
		float glitch_mask = step(0.84 - distortion_intensity * 0.18 - hostile_boost * 0.14, slice_rnd);

		float px_shift = (slice_rnd - 0.5) * 3.2 * TEXTURE_PIXEL_SIZE.x * distortion_intensity * glitch_mask;
		vec2 uv_center = vec2(clamp(UV.x + px_shift, u_min, u_max), UV.y);
		vec4 src = texture(TEXTURE, uv_center);

		// Deslocamento cromático vermelho/sombrio
		float chroma_offset = TEXTURE_PIXEL_SIZE.x * (1.2 + hostile_boost * 1.4) * distortion_intensity;
		float r_shift = texture(TEXTURE, vec2(clamp(uv_center.x + chroma_offset, u_min, u_max), uv_center.y)).r;
		float b_shift = texture(TEXTURE, vec2(clamp(uv_center.x - chroma_offset * 0.65, u_min, u_max), uv_center.y)).b;

		vec3 chroma_col = vec3(
			mix(src.r, r_shift, 0.72),
			src.g * (1.0 - 0.34 * distortion_intensity),
			mix(src.b, b_shift, 0.6) * (1.0 - 0.30 * distortion_intensity)
		);

		// Descoloração + tingimento rubro controlado preservando nitidez de silhueta e leitura em combate
		float luma = dot(chroma_col, vec3(0.299, 0.587, 0.114));
		vec3 grayscale_dark = vec3(clamp(luma * (0.92 - hostile_boost * 0.08) + 0.05, 0.06, 1.0));
		vec3 crimson_shadow = grayscale_dark * dark_red_tint.rgb + vec3(luma * 0.28 * (0.30 + hostile_boost * 0.45), 0.04, 0.05);
		float tint_mix = clamp(distortion_intensity * (0.42 + hostile_boost * 0.16), 0.0, 0.58);
		vec3 final_rgb = mix(chroma_col, crimson_shadow, tint_mix);

		// Scanline horizontal sutil de interferência no sprite distorcido
		float scan = 1.0 - (mod(slice_id, 2.0) * 0.05 * distortion_intensity);
		final_rgb *= scan;

		COLOR = vec4(final_rgb, src.a) * COLOR;
	}
}
