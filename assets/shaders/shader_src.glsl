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






@fs environment_fs
@include_block sprite_fs_main
uniform sampler2D height_tex;
uniform LightParams {
	float tex_width;
	float tex_height;
	float sun_xy_angle;
	float sun_z_angle;
	float shadow_r;
	float shadow_g;
	float shadow_b;
	float max_shadow_steps;
	float max_shadow_height;
	float shadow_fade;
};

vec2 extrude(vec2 other, float angle, float len) {
	float x = len * cos(radians(angle));
	float y = len * sin(radians(angle));
	return vec2(other.x + x, other.y + y);
}

float getHeightAt(vec2 texCoord, float xyAngle, float dist) {
	vec2 newTexCoord = extrude(texCoord, xyAngle, dist);
	float height = texture(height_tex, newTexCoord).r;
	return height;
}

float getTraceHeight(float height, float zAngle, float dist) {
	return dist * tan(radians(zAngle)) + height;
}

vec4 shadow(float xy_angle, float z_angle,vec2 tex_coord, float stp, float max_shadow_steps, float max_shadow_height, float shadow_fade, vec4 shadow_color, vec4 vert_color) {
	float dist;
	float height;
	float other_height;
	float trace_height;
	height = texture(height_tex, tex_coord).r;

	for(int i = 0; i < max_shadow_steps; ++i) {
		dist = stp * float(i);
		other_height = getHeightAt(tex_coord, xy_angle, dist);

		if(other_height > height && other_height - height < max_shadow_height * stp) {
			trace_height = getTraceHeight(height, z_angle, dist);
			if(trace_height < other_height) {
				return clamp(shadow_color + vec4(vec3(dist * shadow_fade), dist * shadow_fade), 0, 1) * vert_color;
			}
		}
	}
	return vert_color;
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {

	const vec2 tex_size = vec2(tex_width, tex_height);
	const float tex_step = 1 / tex_size.y;
	const vec4 shadow_color = vec4( shadow_r, shadow_g, shadow_b, 1);
	

	return shadow(sun_xy_angle, sun_z_angle, tex_coord, tex_step,max_shadow_steps, max_shadow_height,shadow_fade,shadow_color, vert_color);

}
@end
@program environment sprite_vs environment_fs




// RENDERS A LINEAR INTERPOLATED IMAGE AS NEAREST NEIGHBOR
@fs postProcess_fs
@include_block sprite_fs_main
uniform sampler2D shadow_tex;

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

vec2 interpolate (vec2 tex_coord, ivec2 tex_size, float texelsPerPixel) {
	vec2 scaled_tex_coords = tex_coord * tex_size;
	vec2 locationWithinTexel = fract(scaled_tex_coords);
  	vec2 interpolationAmount = clamp(locationWithinTexel / texelsPerPixel, 0, 0.5) + clamp((locationWithinTexel - 1) / texelsPerPixel + 0.5, 0, 0.5);
  	return (floor(scaled_tex_coords) + interpolationAmount) / tex_size;
}


vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {

	ivec2 tex_size = textureSize(tex,0);
	float texelsPerPixel = 8;
	
  	vec2 interpolated_tex_coords = interpolate(tex_coord, tex_size, texelsPerPixel);

	vec4 shadow = tiltshift(shadow_tex, interpolated_tex_coords);
	
	return tiltshift(tex, interpolated_tex_coords) * shadow;  
}
@end

@program postProcess sprite_vs postProcess_fs

#@include example_include_commented_out.glsl


