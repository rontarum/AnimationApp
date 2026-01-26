shader_type canvas_item;
uniform sampler2D screen_texture: hint_screen_texture;
uniform float size : hint_range(1.0, 100.0) = 64.0;
uniform vec3 light_col: source_color = vec3(0.94, 0.92, 0.92);
uniform vec3 gray_col: source_color = vec3(0.78, 0.81, 0.87);

float checker(vec2 p) {
	vec2 q = floor(p);
	return mod(q.x+q.y, 2.);
}

void fragment() {
	vec2 p = FRAGCOORD.xy / size;
	vec4 back_col = vec4(mix(gray_col, light_col, checker(p)), 1.0);
	COLOR = mix(back_col, COLOR, COLOR.a);
}
