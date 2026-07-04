shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec2 viewport_size = vec2(1600.0, 900.0);
uniform vec2 camera_offset = vec2(0.0, 0.0);
uniform float nebula_parallax = 0.06;
uniform float star_parallax_far = 0.04;
uniform float star_parallax_near = 0.14;
uniform float nebula_intensity = 0.62;
uniform float nebula_scale = 380.0;
uniform vec4 nebula_color_blue : hint_color = vec4(0.18, 0.42, 1.0, 1.0);
uniform vec4 nebula_color_mid : hint_color = vec4(0.38, 0.28, 0.95, 1.0);
uniform vec4 nebula_color_purple : hint_color = vec4(0.72, 0.18, 0.92, 1.0);
uniform vec4 star_color : hint_color = vec4(0.82, 0.90, 1.0, 1.0);
uniform float star_density_far = 0.14;
uniform float star_density_near = 0.07;
uniform float cell_size_far = 88.0;
uniform float cell_size_near = 56.0;

float hash11(float p) {
	return fract(sin(p * 127.1) * 43758.5453123);
}

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

float sample_star_layer(vec2 pixel, vec2 parallax, float density, float cell_size) {
	vec2 p = (pixel + parallax) / cell_size;
	vec2 cell = floor(p);
	float rnd = hash12(cell);
	if (rnd > 1.0 - density) {
		vec2 center = cell * cell_size + vec2(hash11(rnd * 17.0), hash11(rnd * 53.0)) * cell_size;
		float dist = length((pixel + parallax) - center);
		float size = 0.7 + hash11(rnd * 91.0) * 1.4;
		float core = smoothstep(size * 0.35, 0.0, dist);
		float glow = smoothstep(size, 0.0, dist) * 0.55;
		float twinkle = 0.55 + 0.45 * sin(TIME * (1.0 + hash11(rnd * 37.0) * 2.8) + rnd * 6.2831853);
		float bright = 0.45 + hash11(rnd * 73.0) * 0.55;
		return (core + glow) * twinkle * bright;
	}
	return 0.0;
}

void fragment() {
	vec2 pixel = UV * viewport_size;

	vec2 neb_uv = (pixel + camera_offset * nebula_parallax) / nebula_scale;
	vec2 drift = vec2(TIME * 0.015, TIME * 0.010);
	float n1 = fbm(neb_uv + drift);
	float n2 = fbm(neb_uv * 1.65 - drift * 0.75 + vec2(3.7, 2.1));
	float n_blend = n1 * 0.6 + n2 * 0.4;

	float neb_mask = smoothstep(0.22, 0.72, n_blend);
	float neb_detail = smoothstep(0.18, 0.55, n2);
	vec3 nebula = mix(nebula_color_blue.rgb, nebula_color_mid.rgb, n1);
	nebula = mix(nebula, nebula_color_purple.rgb, n2 * 0.75);
	float neb_strength = (neb_mask * 0.75 + neb_detail * 0.35) * nebula_intensity;

	float stars_far = sample_star_layer(pixel, camera_offset * star_parallax_far, star_density_far, cell_size_far);
	float stars_near = sample_star_layer(pixel, camera_offset * star_parallax_near, star_density_near, cell_size_near);
	float stars = clamp(stars_far + stars_near * 1.25, 0.0, 1.6);

	float neb_out = neb_strength;
	float star_out = stars * star_color.a;
	vec3 rgb = nebula * neb_out + star_color.rgb * star_out;
	float alpha = clamp(neb_out + star_out * 0.9, 0.0, 1.0);
	COLOR = vec4(rgb * alpha, alpha);
}
