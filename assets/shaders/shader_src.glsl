@vs sprite_vs
uniform VertexParams {
	vec4 transform_matrix[3];
};

layout(location = 0) in vec2 pos_in;
layout(location = 1) in vec2 uv_in;
layout(location = 2) in vec4 color_in;
layout(location = 3) in vec4 options_in;

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

@vs uber_vs
uniform UberVertexParams {
	vec4 transform_matrix[3];
};

layout(location = 0) in vec2 pos_in;
layout(location = 1) in vec2 uv_in;
layout(location = 2) in vec4 color_in;
layout(location = 3) in vec4 options_in;

out vec2 uv_out;
out vec4 color_out;
out vec4 options_out;

void main() {
	uv_out = uv_in;
	color_out = color_in;
	options_out = options_in;
	mat3x2 transMat = mat3x2(transform_matrix[0].x, transform_matrix[0].y, transform_matrix[0].z, transform_matrix[0].w, transform_matrix[1].x, transform_matrix[1].y);

	vec2 pos = pos_in;
	if (options_in.z < 2) {
		pos.x += (sin(options_in.w) * 10) * (0.5 - uv_in.y);
	}

	gl_Position = vec4(transMat * vec3(pos, 1), 0, 1);
}
@end

@block uber_fs_main
uniform sampler2D main_tex;
uniform sampler2D height_tex;

in vec2 uv_out;
in vec4 color_out;
in vec4 options_out;

layout(location = 0) out vec4 frag_color_0;
layout(location = 1) out vec4 frag_color_1;

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color, float frag_mode);
vec4 height(sampler2D tex, vec2 tex_coord, vec4 vert_color, float height);

void main() {
	frag_color_0 = effect(main_tex, uv_out.st, color_out, options_out.y);
	frag_color_1 = height(height_tex, uv_out.st, color_out, options_out.x);
}
@end


// UBER SHADER
@fs uber_fs
@include_block uber_fs_main
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
vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color, float frag_mode) {

	int mode = int(frag_mode);

	vec4 base_color = texture(tex, tex_coord);

	if (mode == 1) {
		ivec2 palette_size = textureSize(palette_tex, 0);
		vec2 palette_coord = paletteCoord(base_color.rgb, (vert_color.rgb * 255) / (palette_size.y - 1));
		base_color = texture(palette_tex, palette_coord) * base_color.a;
	} else {
		base_color = base_color * vert_color;
	}

	return base_color;
}
vec4 height(sampler2D tex, vec2 tex_coord, vec4 vert_color, float height) {
	vec4 sample_height = texture(tex, tex_coord);
	float true_height = sample_height.r * 255 + height;
	float b_height = floor(true_height / 255) / 255;
	float r_height = (true_height - (b_height * 255)) / 255;
	return vec4(r_height, b_height, 0, sample_height.a);
}
@end
@program uber uber_vs uber_fs

@fs environment_fs
@include_block sprite_fs_main

uniform sampler2D height_tex;
uniform sampler2D light_tex;
uniform LightParams {
	float tex_width;
	float tex_height;
	float ambient_xy_angle;
	float ambient_z_angle;
	float shadow_r;
	float shadow_g;
	float shadow_b;
	float shadow_steps;
	//float shadow_fade;
};

bool approx (float a, float b) {
	return abs(b-a) < 0.01;
}

vec2 getTargetTexCoords (float x_step, float y_step, float xy_angle, float h) {
	float x_steps = cos(radians(xy_angle)) * h * x_step;
	float y_steps = sin(radians(xy_angle)) * h * y_step;

	return vec2(x_steps, y_steps);
}

vec4 shadow(float xy_angle, float z_angle, vec2 tex_coord, float stp, float shadow_steps, float tex_step_x, float tex_step_y, vec4 shadow_color, vec4 vert_color) {
	vec4 height_sample = texture(height_tex, tex_coord);
	float height = height_sample.r + height_sample.b * 255;

	for(int i = 0; i < int(shadow_steps); ++i) {
		vec4 other_height_sample = texture(height_tex, tex_coord + getTargetTexCoords(tex_step_x, tex_step_y, xy_angle, float(i)));
		float other_height = other_height_sample.r + other_height_sample.b * 255;

		float dist = distance(tex_coord, tex_coord + getTargetTexCoords(tex_step_x, tex_step_y, xy_angle, float(i)));

		if(other_height > height) {
			float trace_height = dist * tan(radians(z_angle)) + height;
			if(approx(trace_height, other_height)) {
				return shadow_color * vert_color;
			}
		}
	}
	return vert_color;
}

vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {

	const float tex_step_x = float(1) / float(tex_width);
	const float tex_step_y = float(1) / float(tex_height );

	

	const float tex_step =  sqrt(tex_step_x * tex_step_x + tex_step_y * tex_step_y);
	//const float tex_step = tex_step_y;
	const vec4 shadow_color = vec4( shadow_r, shadow_g, shadow_b, 1);

	vec4 shadow = shadow(ambient_xy_angle, ambient_z_angle, tex_coord, tex_step, shadow_steps, tex_step_x, tex_step_y,shadow_color, vert_color);
	vec4 light = texture(light_tex, tex_coord);
	
	return shadow + light;
}
@end
@program environment sprite_vs environment_fs



// @fs emission_fs
// @include_block sprite_fs_main
// uniform sampler2D color_tex;

// vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {

// 	return texture(tex, tex_coord) * texture(color_tex, tex_coord);
// }
// @end

// @program emission sprite_vs emission_fs




// @fs bloom_fs
// @include_block sprite_fs_main

// uniform BloomParams {
// 	float horizontal;
// 	float multiplier;
// 	float tex_size_x;
// 	float tex_size_y;

// };

// const float weight[10] = float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216, 0.0111343, 0.00849020, 0.0040293, 0.0021293, 0.00011234);

// vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {

// 	vec2 tex_offset = 1.0 / vec2(tex_size_x, tex_size_y); // gets size of single texel
//     vec3 result = texture(tex, tex_coord).rgb * weight[0]; // current fragment's contribution
//     if(horizontal > 0)
//     {
//         for(int i = 1; i < 10; ++i)
//         {
//             result += texture(tex, tex_coord + vec2(tex_offset.x * i, 0.0)).rgb * (weight[i] * multiplier);
//             result += texture(tex, tex_coord - vec2(tex_offset.x * i, 0.0)).rgb * (weight[i] * multiplier);
//         }
//     }
//     else
//     {
//         for(int i = 1; i < 10; ++i)
//         {
//             result += texture(tex, tex_coord + vec2(0.0, tex_offset.y * i)).rgb * (weight[i] * multiplier);
//             result += texture(tex, tex_coord - vec2(0.0, tex_offset.y * i)).rgb * (weight[i] * multiplier);
//         }
		
//     }
//     return vec4(result, 1.0);

// }
// @end

// @program bloom sprite_vs bloom_fs





@fs tiltshift_fs
@include_block sprite_fs_main


uniform TiltshiftParams {
	float blur_amount;
};


vec4 effect (sampler2D tex, vec2 tex_coord, vec4 vert_color) {
	const float bluramount  = blur_amount;
	const float center      = 1;
	const float stepSize    = 0.004;
	const float steps       = 4.0;

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

@end

@program tiltshift sprite_vs tiltshift_fs


// RENDERS A LINEAR INTERPOLATED IMAGE AS NEAREST NEIGHBOR
@fs finalize_fs
@include_block sprite_fs_main
//uniform sampler2D bloom_t;
uniform sampler2D envir_t;

uniform FinalizeParams {
	float texel_size;
	float tex_size_x;
	float tex_size_y;
};

vec2 interpolate (vec2 tex_coord, vec2 tex_size, float texelsPerPixel) {
	vec2 scaled_tex_coords = tex_coord * tex_size;
	vec2 locationWithinTexel = fract(scaled_tex_coords);
  	vec2 interpolationAmount = clamp(locationWithinTexel / texelsPerPixel, 0, 0.5) + clamp((locationWithinTexel - 1) / texelsPerPixel + 0.5, 0, 0.5);
  	return (floor(scaled_tex_coords) + interpolationAmount) / tex_size;
}


vec4 effect(sampler2D tex, vec2 tex_coord, vec4 vert_color) {

	vec2 tex_size = vec2(tex_size_x, tex_size_y);
	float texelsPerPixel = texel_size;
	
  	vec2 interpolated_tex_coords =  interpolate(tex_coord, tex_size, texelsPerPixel);

	//vec4 bloom = texture(bloom_t, tex_coord);
	vec4 environment = texture(envir_t, interpolated_tex_coords);
	vec4 main = texture(tex, interpolated_tex_coords);

	return main * environment; //bloom;  
}
@end

@program finalize sprite_vs finalize_fs

#@include example_include_commented_out.glsl


