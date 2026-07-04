shader_type canvas_item;
render_mode blend_mix;

uniform vec2 ellipse_scale = vec2(0.46, 0.32);
uniform float softness = 0.04;
uniform float rotation_angle = 0.0;
uniform vec4 glow_color : hint_color = vec4(0.15, 0.95, 0.55, 0.9);
uniform float glow_width = 0.16;
uniform float glow_intensity = 1.0;

float ellipse_dist(vec2 uv) {
	return (uv.x * uv.x) / (ellipse_scale.x * ellipse_scale.x)
		+ (uv.y * uv.y) / (ellipse_scale.y * ellipse_scale.y);
}

vec2 rotate_uv(vec2 uv, float angle) {
	vec2 centered = uv - vec2(0.5);
	float c = cos(angle);
	float s = sin(angle);
	return vec2(
		centered.x * c - centered.y * s,
		centered.x * s + centered.y * c
	) + vec2(0.5);
}

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = ellipse_dist(uv);

	float mask = 1.0 - smoothstep(1.0 - softness, 1.0 + softness, dist);
	vec4 tex = texture(TEXTURE, rotate_uv(UV, rotation_angle));

	float glow = 0.0;
	float outside = dist - 1.0;
	if (outside > 0.0) {
		glow = (1.0 - smoothstep(0.0, glow_width, outside)) * glow_intensity;
	}
	vec3 glow_rgb = glow_color.rgb * glow * glow_color.a;
	float glow_a = glow * glow_color.a;

	vec3 rgb = tex.rgb * mask * tex.a + glow_rgb;
	float alpha = max(tex.a * mask, glow_a);
	COLOR = vec4(rgb, alpha);
}
