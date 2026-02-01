shader_type canvas_item;

uniform sampler2D screen_tex: hint_screen_texture;
uniform vec2 mouse_pos;

uniform int state = 0;
uniform bool is_picking = false;
uniform vec4 swatch: source_color;

const int PENCIL = 0;
const int ERASER = 1;

void fragment() {
	ivec2 p = ivec2(FRAGCOORD.xy);
	vec4 color = texelFetch(TEXTURE, p, 0);
	float point = float(p == ivec2(mouse_pos)) * float(!is_picking) * float(state != ERASER);
	COLOR = mix(color, swatch, point);
}