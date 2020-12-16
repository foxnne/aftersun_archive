@vs sprite_vs
uniform VertexParams {
	vec4 transform_matrix[2];
};

layout(location = 0) in vec2 pos_in;
layout(location = 1) in vec2 uv_in;
layout(location = 2) in vec4 color_in;

out vec2 uv_out;
out vec4 color_out;

void main() {
	uv_out = uv_in;
	color_out = color_in;
	mat3x2 transMat = mat3x2(transform_matrix[0].x, transform_matrix[0].y, transform_matrix[0].z, transform_matrix[0].w, transform_matrix[1].x, transform_matrix[1].y);

	gl_Position = vec4(transMat * vec3(pos_in, 1), 0, 1);
}
@end


@block sprite_fs_main
uniform sampler2D main_tex;

in vec2 uv_out;
in vec4 color_out;
out vec4 frag_color;

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color);

void main() {
	frag_color = effect(main_tex, uv_out.st, color_out);
}
@end


@fs sprite_fs
@include_block sprite_fs_main
vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {
	return texture(tex, tex_coord) * vert_color;
}
@end

@program sprite sprite_vs sprite_fs


@fs spritePalette_fs
@include_block sprite_fs_main
uniform sampler2D palette_tex;

int max3 (vec3 channels) {
	return int(max(channels.b, max (channels.g, channels.r)));
}
vec2 paletteCoord (vec3 base, vec3 vert) {
	// blue overwrites green which overwrites red
	// arranged such that if all are 0, order is respected
	vec3 channels = vec3(
		//b
		clamp(base.x * vert.x * 65025, 0.0, 1.0) * 3,
		//g
		clamp(base.y * vert.y * 65025, 0.0, 1.0) * 2,
		//r
		clamp(base.z * vert.z * 65025, 0.0, 1.0)
	);

	int index = clamp(max3(channels) - 1, 0, 2);

	return vec2(base.bgr[index], vert.bgr[index]);
}
vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {
	vec4 base_color = texture(tex, tex_coord);
	ivec2 palette_size = textureSize(palette_tex, 0);
	// swizzle channels such that 0 is blue for transparency overwriting
	vec2 palette_coord = paletteCoord(base_color.brg, (vert_color.brg * 255) / (palette_size.y - 1));
	vec4 palette_color = texture(palette_tex, palette_coord);

	return palette_color * base_color.a * vert_color.a;
}
@end

@program spritePalette sprite_vs spritePalette_fs

#@include example_include_commented_out.glsl