shader_type canvas_item;

// vhs_glitch_tear.gdshader - Glitch de tela cheia para eventos de fita em Huwag
// Aplicado como overlay acima de tudo apenas durante um "evento de glitch":
// rasga blocos horizontais, separa canais RGB com deslocamento e injeta estática.
// Fora do evento o nó fica invisível, então não consome desenho.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

// 0.0 = sem efeito; 1.0 = glitch máximo no início do evento.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

float random_noise(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col;

	if (intensity <= 0.001) {
		col = texture(screen_tex, uv).rgb;
		COLOR = vec4(col, 1.0);
	} else {
		// Rasga blocos horizontais inteiros, deslocando-os lateralmente.
		float block = floor(uv.y * 28.0);
		float frame = floor(TIME * 22.0);
		float tear = random_noise(vec2(block, frame));
		if (tear > 1.0 - intensity * 0.3) {
			uv.x += (random_noise(vec2(block + 9.7, frame)) - 0.5) * 0.05 * intensity;
		}

		// Separação cromática que cresce com a intensidade.
		float shift = 0.008 * intensity;
		float r = texture(screen_tex, vec2(uv.x + shift, uv.y)).r;
		float g = texture(screen_tex, uv).g;
		float b = texture(screen_tex, vec2(uv.x - shift, uv.y)).b;
		col = vec3(r, g, b);

		// Injeção de estática analógica.
		col += (random_noise(uv + vec2(TIME * 13.0, TIME * 7.0)) - 0.5) * 0.22 * intensity;

		// Leve brilho de "dropout" durante o pico do glitch.
		col += vec3(0.1) * intensity;

		COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
	}
}