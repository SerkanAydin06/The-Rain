shader_type canvas_item;

uniform float glow_strength : hint_range(0, 1) = 0.5;
uniform vec4 glow_color : source_color = vec4(0.3, 0.6, 1.0, 0.5);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	
	// Glow efekti
	float pulse = sin(TIME * 3.0) * 0.2 + 0.8;
	float glow = glow_strength * pulse;
	
	color.rgb = mix(color.rgb, glow_color.rgb, glow * glow_color.a);
	color.a = max(color.a, glow * glow_color.a * 0.5);
	
	COLOR = color;
}