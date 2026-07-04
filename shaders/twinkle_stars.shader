shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec2 viewport_size = vec2(1600.0, 900.0);
uniform vec2 camera_offset = vec2(0.0, 0.0);
uniform float star_parallax = 0.12;
uniform vec4 twinkle_color : hint_color = vec4(0.92, 0.97, 1.0, 1.0);
uniform float twinkle_density = 0.04;
uniform float cell_size = 110.0;

float hash11(float p) {
	return fract(sin(p * 127.1) * 43758.5453123);
}

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float sample_sharp_twinkle(vec2 pixel, vec2 parallax) {
	vec2 p = (pixel + parallax) / cell_size;
	vec2 cell = floor(p);
	float rnd = hash12(cell);

	if (rnd > 1.0 - twinkle_density) {
		vec2 center = cell * cell_size + vec2(
			hash11(rnd * 17.0),
			hash11(rnd * 53.0)
		) * cell_size;
		vec2 d = (pixel + parallax) - center;

		if (max(abs(d.x), abs(d.y)) <= 0.5) {
			float phase = rnd * 6.2831853;
			float speed = 1.5 + hash11(rnd * 91.0) * 4.0;
			float wave = 0.5 + 0.5 * sin(TIME * speed + phase);
			return step(0.45, wave);
		}
	}

	return 0.0;
}

void fragment() {
	vec2 pixel = UV * viewport_size;
	vec2 parallax = camera_offset * star_parallax;
	float v = sample_sharp_twinkle(pixel, parallax);

	if (v > 0.0) {
		COLOR = vec4(twinkle_color.rgb * v, v * twinkle_color.a);
	} else {
		COLOR = vec4(0.0);
	}
}
