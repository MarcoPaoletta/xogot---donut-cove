shader_type spatial;
render_mode cull_back, shadows_disabled, depth_draw_never;
// The hologram of something a pad buys. It is laid over the real object as a
// material overlay: above `fill_y` (world height) the object is the mint
// hologram, below it the real object shows. The pad raises `fill_y` as it is
// paid, so the purchase fills in from the ground up.

uniform vec4 tint : source_color = vec4(0.36, 0.96, 0.7, 0.86);
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 0.85, 1.0);
uniform float fill_y = -1000.0;
// For flat things (a floor): the hologram fades out instead of filling up.
uniform float fade = 1.0;
uniform float edge_height = 0.07;

varying float world_y;

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	if (world_y < fill_y) {
		discard;
	}
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.5);
	float edge = 1.0 - smoothstep(0.0, edge_height, world_y - fill_y);
	float bands = 0.5 + 0.5 * sin(world_y * 26.0 - TIME * 2.4);
	vec3 color = tint.rgb * (0.82 + 0.1 * bands) + vec3(rim * 0.35);
	ALBEDO = mix(color, edge_color.rgb, edge);
	EMISSION = mix(tint.rgb * 0.38, edge_color.rgb * 0.9, edge);
	ROUGHNESS = 0.7;
	ALPHA = clamp((tint.a + rim * 0.14) * fade + edge * 0.2, 0.0, 1.0);
}
