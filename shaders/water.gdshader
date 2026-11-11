shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, specular_schlick_ggx;

// The sea of Donut Cove: one plane. Colour by depth (turquoise shallows to a
// deeper blue), white foam where the water meets sand, rocks, posts and the
// hull, gentle vertex waves, faceted light patches and sun glints.
// `sea_time` is a global written by the Sea node, so scripts that bob on the
// water (ship, loot, sharks) use the same clock as the waves.

global uniform float sea_time;

uniform vec3 shallow_color : source_color = vec3(0.10, 0.80, 0.78);
uniform vec3 mid_color : source_color = vec3(0.04, 0.72, 0.84);
uniform vec3 deep_color : source_color = vec3(0.0, 0.58, 0.84);
uniform vec3 foam_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float depth_fade = 2.4;
uniform float foam_width = 0.11;
uniform float wave_height = 0.10;
uniform float wave_length = 14.0;
uniform float facet_scale = 0.22;
uniform float facet_strength = 0.05;
uniform float sparkle_strength = 0.55;
uniform float fog_start = 90.0;
uniform float fog_end = 260.0;
uniform vec3 horizon_color : source_color = vec3(0.45, 0.83, 0.95);
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Cellular pattern: flat cells with soft borders, the low poly water look.
vec2 cells(vec2 p, float t) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float best = 8.0;
	float id = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			float h = hash21(i + g);
			vec2 o = 0.5 + 0.38 * sin(t * 0.7 + 6.2831 * vec2(h, fract(h * 7.13)));
			float d = length(g + o - f);
			if (d < best) {
				best = d;
				id = h;
			}
		}
	}
	return vec2(best, id);
}

float wave(vec2 p, float t) {
	float k = 6.2831 / wave_length;
	return sin(p.x * k + t * 1.1) * 0.6 + sin(p.y * k * 1.3 - t * 0.9) * 0.4 + sin((p.x + p.y) * k * 0.6 + t * 0.6) * 0.3;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += wave(world_pos.xz, sea_time) * wave_height;
	world_pos.y = VERTEX.y;
}

void fragment() {
	float scene_depth = texture(depth_texture, SCREEN_UV).r;
	vec4 scene_view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, scene_depth, 1.0);
	scene_view.xyz /= scene_view.w;
	vec3 scene_world = (INV_VIEW_MATRIX * vec4(scene_view.xyz, 1.0)).xyz;
	// Vertical water depth: the same at every view angle, so the foam band keeps its width.
	float depth_below = max(world_pos.y - scene_world.y, 0.0);
	float t = clamp(depth_below / depth_fade, 0.0, 1.0);
	vec3 color = mix(shallow_color, mid_color, smoothstep(0.0, 0.45, t));
	color = mix(color, deep_color, smoothstep(0.35, 1.0, t));

	vec2 cell = cells(world_pos.xz * facet_scale, sea_time);
	color += (cell.y - 0.5) * facet_strength;
	color += smoothstep(0.44, 0.5, cell.x) * 0.06;

	// Foam: a solid band at the contact line and a thin ripple that drifts out.
	float wobble = sin(sea_time * 1.6 + world_pos.x * 0.9 + world_pos.z * 0.7) * 0.5 + 0.5;
	float edge = foam_width * (0.6 + 0.4 * wobble);
	float band = 1.0 - smoothstep(edge * 0.75, edge, depth_below);
	float phase = fract(sea_time * 0.2 + cell.y * 0.15);
	float ripple_at = foam_width * (1.5 + 2.5 * phase);
	float ripple = (1.0 - smoothstep(0.0, foam_width * 0.22, abs(depth_below - ripple_at))) * (1.0 - phase) * 0.45;
	float foam = clamp(band + ripple, 0.0, 1.0);
	color = mix(color, foam_color, foam);

	// Sun glints: sparse bright points that twinkle.
	vec2 sp = world_pos.xz * 1.7;
	float spark = hash21(floor(sp));
	float twinkle = sin(sea_time * 3.0 + spark * 40.0) * 0.5 + 0.5;
	float glint = step(0.965, spark) * smoothstep(0.35, 0.0, length(fract(sp) - 0.5)) * twinkle;
	color += glint * sparkle_strength;

	// Distance haze toward the horizon, so the sea meets the sky softly.
	float dist = length(VERTEX);
	color = mix(color, horizon_color, smoothstep(fog_start, fog_end, dist) * 0.85);

	ALBEDO = color;
	ROUGHNESS = 0.22;
	METALLIC = 0.0;
	SPECULAR = 0.35;
	EMISSION = foam_color * glint * sparkle_strength * 0.8;
	ALPHA = mix(0.86, 1.0, smoothstep(0.0, 0.5, t));
}
