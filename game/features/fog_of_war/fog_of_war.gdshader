shader_type canvas_item;

const int MAX_ROOM_RECTS = 64;
uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform vec2 focus_position = vec2(640.0, 360.0);
uniform vec2 facing_direction = vec2(1.0, 0.0);
uniform float corridor_near_radius = 170.0;
uniform float corridor_forward_distance = 780.0;
uniform float corridor_half_angle_radians = 1.0821;
uniform float corridor_angle_softness_radians = 0.2094;
uniform float corridor_distance_softness = 130.0;
uniform float room_edge_softness = 18.0;
uniform float room_visibility_blend = 0.0;
uniform vec4 active_room_rect = vec4(0.0);
uniform int room_count = 0;
uniform vec4 room_rects[MAX_ROOM_RECTS];
uniform vec4 fog_color : source_color = vec4(0.008, 0.014, 0.025, 0.97);


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
	float blocked = 0.0;
	for (int index = 0; index < MAX_ROOM_RECTS; index++) {
		if (index >= room_count) {
			break;
		}
		blocked = max(blocked, inside_rect(point, room_rects[index]));
	}
	return blocked;
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
	float visibility = max(near_visibility, cone * in_front * distance_visibility);
	return visibility * (1.0 - room_block_mask(pixel_position));
}


void fragment() {
	vec2 pixel_position = UV * viewport_size;
	float corridor = corridor_visibility(pixel_position);
	float room = soft_rect_visibility(
		pixel_position, active_room_rect, room_edge_softness
	);
	float eased_blend = smoothstep(0.0, 1.0, room_visibility_blend);
	float visibility = mix(corridor, room, eased_blend);
	COLOR = vec4(
		fog_color.rgb,
		fog_color.a * (1.0 - clamp(visibility, 0.0, 1.0))
	);
}
