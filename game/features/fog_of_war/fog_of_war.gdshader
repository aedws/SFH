shader_type canvas_item;

const int MAX_ROOM_RECTS = 64;
const int MAX_OCCLUSION_RAYS = 48;
const float TAU_VALUE = 6.28318530718;
uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform vec2 focus_position = vec2(640.0, 360.0);
uniform vec2 facing_direction = vec2(1.0, 0.0);
uniform float corridor_near_radius = 170.0;
uniform float corridor_forward_distance = 780.0;
uniform float corridor_half_angle_radians = 1.0821;
uniform float corridor_angle_softness_radians = 0.2094;
uniform float corridor_distance_softness = 130.0;
uniform float corridor_comfort_shell_radius = 320.0;
uniform float corridor_comfort_shell_visibility = 0.24;
uniform float room_edge_softness = 18.0;
uniform float room_visibility_blend = 0.0;
uniform vec4 active_room_rect = vec4(0.0);
uniform float previous_room_visibility_blend = 0.0;
uniform vec4 previous_room_rect = vec4(0.0);
uniform int room_count = 0;
uniform vec4 room_rects[MAX_ROOM_RECTS];
uniform float room_memory[MAX_ROOM_RECTS];
uniform bool occlusion_enabled = true;
uniform float occlusion_distances[MAX_OCCLUSION_RAYS];
uniform float occlusion_edge_softness = 18.0;
uniform float explored_room_tint_strength = 0.12;
uniform float fog_noise_strength = 0.008;
uniform vec4 fog_color : source_color = vec4(0.008, 0.014, 0.025, 0.97);
uniform vec4 explored_fog_color : source_color = vec4(0.006, 0.09, 0.11, 0.97);


float inside_rect(vec2 point, vec4 rect) {
	return step(rect.x, point.x) * step(point.x, rect.z)
		* step(rect.y, point.y) * step(point.y, rect.w);
}


float soft_rect_visibility(vec2 point, vec4 rect, float softness) {
	float signed_edge = min(
		min(point.x - rect.x, rect.z - point.x),
		min(point.y - rect.y, rect.w - point.y)
	);
	return smoothstep(-softness, max(1.0, softness), signed_edge);
}


float room_block_mask(vec2 point) {
	if (inside_rect(point, active_room_rect) > 0.5) {
		return 0.0;
	}
	if (
		previous_room_visibility_blend > 0.001
		&& inside_rect(point, previous_room_rect) > 0.5
	) {
		return 0.0;
	}
	float blocked = 0.0;
	for (int index = 0; index < MAX_ROOM_RECTS; index++) {
		if (index >= room_count) {
			break;
		}
		blocked = max(blocked, inside_rect(point, room_rects[index]));
	}
	return blocked;
}


float explored_room_mask(vec2 point) {
	float explored = 0.0;
	for (int index = 0; index < MAX_ROOM_RECTS; index++) {
		if (index >= room_count) {
			break;
		}
		explored = max(explored, inside_rect(point, room_rects[index]) * room_memory[index]);
	}
	return explored;
}


float ray_occlusion(vec2 delta) {
	if (!occlusion_enabled) {
		return 1.0;
	}
	float radial_distance = length(delta);
	float normalized_angle = fract((atan(delta.y, delta.x) + TAU_VALUE) / TAU_VALUE);
	float ray_position = normalized_angle * float(MAX_OCCLUSION_RAYS);
	int ray_a = int(floor(ray_position)) % MAX_OCCLUSION_RAYS;
	int ray_b = (ray_a + 1) % MAX_OCCLUSION_RAYS;
	float visible_distance = mix(
		occlusion_distances[ray_a], occlusion_distances[ray_b], fract(ray_position)
	);
	return 1.0 - smoothstep(
		max(0.0, visible_distance - occlusion_edge_softness),
		visible_distance + occlusion_edge_softness,
		radial_distance
	);
}


float corridor_visibility(vec2 pixel_position) {
	vec2 delta = pixel_position - focus_position;
	float radial_distance = length(delta);
	vec2 direction_to_pixel = radial_distance > 0.001
		? delta / radial_distance
		: facing_direction;
	vec2 normalized_facing = normalize(facing_direction);
	float facing_dot = dot(direction_to_pixel, normalized_facing);
	float outer_angle = corridor_half_angle_radians + corridor_angle_softness_radians;
	float cone = smoothstep(
		cos(outer_angle), cos(corridor_half_angle_radians), facing_dot
	);
	float forward = dot(delta, normalized_facing);
	float in_front = smoothstep(-24.0, 48.0, forward);
	float distance_visibility = 1.0 - smoothstep(
		max(0.0, corridor_forward_distance - corridor_distance_softness),
		corridor_forward_distance,
		radial_distance
	);
	float near_visibility = 1.0 - smoothstep(
		corridor_near_radius * 0.62, corridor_near_radius, radial_distance
	);
	float comfort_shell = (
		1.0 - smoothstep(corridor_near_radius, corridor_comfort_shell_radius, radial_distance)
	) * corridor_comfort_shell_visibility;
	float visibility = max(max(near_visibility, comfort_shell), cone * in_front * distance_visibility);
	return visibility * ray_occlusion(delta) * (1.0 - room_block_mask(pixel_position));
}


void fragment() {
	vec2 pixel_position = UV * viewport_size;
	float corridor = corridor_visibility(pixel_position);
	float room = soft_rect_visibility(
		pixel_position, active_room_rect, room_edge_softness
	);
	float previous_room = soft_rect_visibility(
		pixel_position, previous_room_rect, room_edge_softness
	) * smoothstep(0.0, 1.0, previous_room_visibility_blend);
	float eased_blend = smoothstep(0.0, 1.0, room_visibility_blend);
	float visibility = max(mix(corridor, room, eased_blend), previous_room);
	float memory = explored_room_mask(pixel_position) * (1.0 - visibility);
	vec3 base_fog = mix(
		fog_color.rgb,
		explored_fog_color.rgb,
		memory * explored_room_tint_strength
	);
	float static_noise = fract(
		sin(dot(floor(pixel_position * 0.5), vec2(12.9898, 78.233))) * 43758.5453
	);
	base_fog += (static_noise - 0.5) * fog_noise_strength * (1.0 - visibility);
	COLOR = vec4(
		base_fog,
		fog_color.a * (1.0 - clamp(visibility, 0.0, 1.0))
	);
}
