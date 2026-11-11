shader_type spatial;
render_mode cull_back;

// The sand of the island: one surface. Warm dry sand on top, a darker wet rim
// near the waterline (by world height, so nothing is coplanar), and soft
// large patches of lighter and darker sand so the plateau is not flat colour.

uniform vec3 dry_color : source_color = vec3(0.93, 0.66, 0.30);
uniform vec3 light_color : source_color = vec3(0.97, 0.75, 0.40);
uniform vec3 wet_color : source_color = vec3(0.74, 0.55, 0.30);
uniform float wet_top = -0.12;
uniform float wet_bottom = -0.5;
uniform float patch_scale = 0.11;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.45);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = noise(world_pos.xz * patch_scale) * 0.65 + noise(world_pos.xz * patch_scale * 2.7) * 0.35;
	vec3 color = mix(dry_color, light_color, smoothstep(0.35, 0.8, n));
	float wet = 1.0 - smoothstep(wet_bottom, wet_top, world_pos.y);
	color = mix(color, wet_color, wet);
	ALBEDO = color;
	ROUGHNESS = mix(0.95, 0.55, wet);
	SPECULAR = mix(0.2, 0.5, wet);
}
