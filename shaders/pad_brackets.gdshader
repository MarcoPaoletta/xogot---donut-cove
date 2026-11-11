shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;
// The buy marker on the floor: four rounded corner brackets and no fill.
// Drawn on a flat quad. `progress` (per instance) paints the brackets from
// white to the paid colour while the coins drain.

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.96);
uniform vec4 paid_color : source_color = vec4(0.42, 1.0, 0.62, 1.0);
uniform vec4 shade_color : source_color = vec4(0.28, 0.16, 0.08, 0.3);
// All sizes are fractions of half the quad.
uniform float corner_radius = 0.34;
uniform float thickness = 0.1;
// Half length of the opening in the middle of every side.
uniform float gap = 0.3;
uniform float shade_offset = 0.035;
instance uniform float progress = 0.0;

float bracket(vec2 p) {
	float inset = thickness * 0.5 + 0.03;
	vec2 q = abs(p) - (vec2(1.0 - inset) - vec2(corner_radius));
	float box = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
	float ring = abs(box) - thickness * 0.5;
	// Rounded ends: the distance to the opening on each side.
	float cut = min(abs(p.x), abs(p.y)) - gap;
	float d = max(ring, -cut);
	return 1.0 - smoothstep(-0.012, 0.012, d);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float line = bracket(p);
	float shade = bracket(p - vec2(shade_offset, shade_offset)) * (1.0 - line);
	// Paid part: sweeps around the square from the back, like a clock.
	float turn = atan(p.x, -p.y) / 6.2831853 + 0.5;
	vec3 tint = mix(line_color.rgb, paid_color.rgb, step(turn, progress));
	ALBEDO = mix(shade_color.rgb, tint, line);
	ALPHA = max(line * line_color.a, shade * shade_color.a);
}
