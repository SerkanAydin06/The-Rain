shader_type canvas_item;
// Ana menü arka planı: karartma, yeşilimsi ton ve vinyet
uniform float darkness : hint_range(0.0, 1.0) = 0.72;
uniform vec3 tint : source_color = vec3(0.55, 0.68, 0.45);
uniform float vignette : hint_range(0.0, 2.0) = 1.15;
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(vec3(lum), c.rgb, 0.35) * tint;
	col *= (1.0 - darkness);
	vec2 d = UV - vec2(0.5);
	float v = 1.0 - clamp(dot(d, d) * vignette * 2.2, 0.0, 1.0);
	col *= v;
	// Sol taraf menü için ekstra koyu
	col *= mix(0.45, 1.0, smoothstep(0.0, 0.55, UV.x));
	col += flash * vec3(0.75, 0.85, 0.8);
	COLOR = vec4(col, 1.0);
}
