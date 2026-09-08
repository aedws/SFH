shader_type canvas_item;
// Opaque remembered terrain, NOT a translucent view of moving actors underneath.
uniform sampler2D visibility_map : filter_nearest, repeat_disable;
uniform vec2 viewport_size;
uniform vec2 screen_world_origin;
uniform vec2 screen_world_x = vec2(1.0, 0.0);
uniform vec2 screen_world_y = vec2(0.0, 1.0);
uniform vec2 grid_origin;
uniform vec2 grid_size;
uniform float cell_size = 32.0;
uniform vec2 focus_world;
uniform float sight_radius = 640.0;
uniform int door_count = 0;
uniform vec4 door_rects[64];

float doors_visible(vec2 world) {
	vec2 delta = world - focus_world;
	vec2 safe_delta = vec2(abs(delta.x) < 0.001 ? 0.001 : delta.x, abs(delta.y) < 0.001 ? 0.001 : delta.y);
	for (int i = 0; i < 64; i++) {
		if (i >= door_count) { break; }
		vec4 rect = door_rects[i];
		// The door face itself stays readable; nothing beyond the actual thin barrier leaks.
		if (world.x >= rect.x && world.x <= rect.z && world.y >= rect.y && world.y <= rect.w) { continue; }
		vec2 a = (rect.xy-focus_world) / safe_delta;
		vec2 b = (rect.zw-focus_world) / safe_delta;
		vec2 lo = min(a,b);
		vec2 hi = max(a,b);
		float enter = max(lo.x,lo.y);
		float leave = min(hi.x,hi.y);
		if (enter <= leave && leave > 0.0 && enter < 1.0) { return 0.0; }
	}
	return 1.0;
}

void fragment() {
	vec2 screen = UV * viewport_size;
	vec2 world = screen_world_origin + screen_world_x * screen.x + screen_world_y * screen.y;
	vec2 grid = (world - grid_origin) / cell_size;
	vec2 cell = floor(grid);
	vec2 map_uv = (cell + vec2(0.5)) / grid_size;
	float inside = step(0.0, cell.x) * step(0.0, cell.y) * (1.0-step(grid_size.x, cell.x)) * (1.0-step(grid_size.y, cell.y));
	vec4 data = texture(visibility_map, map_uv) * inside;
	float checker = mod(cell.x + cell.y, 2.0);
	vec3 memory_floor = mix(vec3(0.033, 0.052, 0.066), vec3(0.044, 0.066, 0.080), checker);
	float is_wall = step(0.5, data.b);
	vec2 edge = min(fract(grid), vec2(1.0) - fract(grid));
	float inset = smoothstep(0.0, 0.08, min(edge.x, edge.y));
	vec3 memory_wall = mix(vec3(0.17, 0.21, 0.25), vec3(0.10, 0.14, 0.18), inset);
	vec3 remembered = mix(memory_floor, memory_wall, is_wall);
	vec3 fog = mix(vec3(0.006, 0.010, 0.016), remembered, data.g);
	float range_fade = 1.0 - smoothstep(max(1.0, sight_radius - cell_size * 1.5), sight_radius, length(world-focus_world));
	// Only soften INSIDE visible cells. Adjacent hidden cells remain fully opaque.
	vec2 corner_uv = (cell + vec2(0.5)) / grid_size;
	float left = texture(visibility_map, corner_uv - vec2(1.0/grid_size.x, 0.0)).r;
	float right = texture(visibility_map, corner_uv + vec2(1.0/grid_size.x, 0.0)).r;
	float up = texture(visibility_map, corner_uv - vec2(0.0, 1.0/grid_size.y)).r;
	float down = texture(visibility_map, corner_uv + vec2(0.0, 1.0/grid_size.y)).r;
	vec2 f = fract(grid);
	float interior = min(min(mix(smoothstep(0.0, 0.18, f.x), 1.0, left), mix(smoothstep(0.0, 0.18, 1.0-f.x), 1.0, right)), min(mix(smoothstep(0.0, 0.18, f.y), 1.0, up), mix(smoothstep(0.0, 0.18, 1.0-f.y), 1.0, down)));
	COLOR = vec4(fog, 1.0 - data.r * range_fade * interior * doors_visible(world));
}
