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

// RENDERS INDEXED SPRITES USING A PALETTE, SPLITTING THE THREE
// CHANNELS INTO "LAYERS", PALETTE INDEX IS CHANNEL COLOR (0-255)
@fs spritePalette_fs
@include_block sprite_fs_main
uniform sampler2D palette_tex;

int max3 (vec3 channels) {
	return int(max(channels.z, max (channels.y, channels.x)));
}
vec2 paletteCoord (vec3 base, vec3 vert) {
	// blue overwrites green which overwrites red
	// arranged such that if all are 0, order is respected
	vec3 channels = vec3(
		//r
		clamp(base.x * vert.x * 65025, 0.0, 1.0),
		//g
		clamp(base.y * vert.y * 65025, 0.0, 1.0) * 2,
		//b
		clamp(base.z * vert.z * 65025, 0.0, 1.0) * 3
	);

	int index = max3(channels);

	return vec2(base.brgb[index], vert.brgb[index]);
}
vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {
	vec4 base_color = texture(tex, tex_coord);
	ivec2 palette_size = textureSize(palette_tex, 0);
	vec2 palette_coord = paletteCoord(base_color.rgb, (vert_color.rgb * 255) / (palette_size.y - 1));
	vec4 palette_color = texture(palette_tex, palette_coord);

	return palette_color * base_color.a * vert_color.a;
}
@end

@program spritePalette sprite_vs spritePalette_fs


// RENDERS A LINEAR INTERPOLATED IMAGE AS NEAREST NEIGHBOR
@fs pixelPerfect_fs
@include_block sprite_fs_main


vec4 tiltshift (sampler2D tex, vec2 tex_coord) {
	const float bluramount  = 1;
	const float center      = 1;
	const float stepSize    = 0.004;
	const float steps       = 3.0;

	const float minOffs     = (float(steps-1.0)) / -2.0;
	const float maxOffs     = (float(steps-1.0)) / +2.0;

	float amount;
    vec4 blurred;
        
        //Work out how much to blur based on the mid point 
    amount = pow((tex_coord.y * center) * 2.0 - 1.0, 2.0) * bluramount;
        
        //This is the accumulation of color from the surrounding pixels in the texture
    blurred = vec4(0.0, 0.0, 0.0, 1.0);
        
        //From minimum offset to maximum offset
    for (float offsX = minOffs; offsX <= maxOffs; ++offsX) {
        for (float offsY = minOffs; offsY <= maxOffs; ++offsY) {

                //copy the coord so we can mess with it
            vec2 temp_tcoord = tex_coord.xy;

                //work out which uv we want to sample now
            temp_tcoord.x += offsX * amount * stepSize;
            temp_tcoord.y += offsY * amount * stepSize;

                //accumulate the sample 
            blurred += texture(tex, temp_tcoord);
        
        } //for y
    } //for x 
        
        //because we are doing an average, we divide by the amount (x AND y, hence steps * steps)
    return blurred /= float(steps * steps);
      
}


vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {

	ivec2 tex_size = textureSize(tex,0);
	vec2 scaled_tex_coords = tex_coord * tex_size;
	float texelsPerPixel = 8;
	vec2 locationWithinTexel = fract(scaled_tex_coords);
  	vec2 interpolationAmount = clamp(locationWithinTexel / texelsPerPixel, 0, 0.5) + clamp((locationWithinTexel - 1) / texelsPerPixel + 0.5, 0, 0.5);
  	vec2 finalTextureCoords = (floor(scaled_tex_coords) + interpolationAmount) / tex_size;
	


  	// return texture(tex, finalTextureCoords) * vert_color;

	return tiltshift(tex, finalTextureCoords) * vert_color;  
}
@end

@program pixelPerfect sprite_vs pixelPerfect_fs

#@include example_include_commented_out.glsl


