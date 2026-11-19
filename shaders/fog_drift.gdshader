shader_type canvas_item;

// Névoa atmosférica 16-bit top-down (Compatível com gl_compatibility / Nearest).
// Quantizada em texels virtuais para evitar desfoque liso sobre pixel art.

uniform vec4 fog_color : source_color = vec4(0.58, 0.65, 0.76, 1.0);
uniform vec4 distorted_color : source_color = vec4(0.14, 0.12, 0.24, 1.0);
uniform float fog_density : hint_range(0.0, 1.0) = 0.28;
uniform float distortion_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec2 drift_speed = vec2(0.018, -0.007);
uniform vec2 pixel_resolution = vec2(320.0, 180.0);
uniform float edge_fade : hint_range(0.0, 0.45) = 0.10;
uniform float quantize_steps : hint_range(2.0, 12.0, 1.0) = 5.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		v += amp * value_noise(p);
		p *= 2.03;
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = floor(UV * pixel_resolution) / pixel_resolution;
	vec2 flow_a = uv * 4.5 + TIME * drift_speed;
	vec2 flow_b = uv * 7.5 - TIME * (drift_speed * 0.65) + vec2(3.7, 1.9);

	float n = fbm(flow_a) * 0.62 + fbm(flow_b) * 0.38;
	float wisps = smoothstep(0.36, 0.78, n);
	float banded = floor(wisps * quantize_steps) / quantize_steps;

	float border_x = smoothstep(0.0, edge_fade, uv.x) * smoothstep(0.0, edge_fade, 1.0 - uv.x);
	float border_y = smoothstep(0.0, edge_fade, uv.y) * smoothstep(0.0, edge_fade, 1.0 - uv.y);
	float mask = edge_fade > 0.001 ? (border_x * border_y) : 1.0;

	vec3 col = mix(fog_color.rgb, distorted_color.rgb, distortion_mix * 0.65);
	float alpha = clamp(banded * fog_density * mask, 0.0, 0.85);
	COLOR = vec4(col, alpha);
}
