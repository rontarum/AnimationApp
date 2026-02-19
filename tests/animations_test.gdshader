shader_type canvas_item;

uniform int idx: hint_range(0, 8, 1);

void vertex() {
	if (VERTEX_ID == idx) {
		VERTEX += sin(TIME * 0.7);
	}
	
}
