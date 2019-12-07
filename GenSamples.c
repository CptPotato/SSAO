// generate sampling kernel (result printed to stdout)

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define SAMPLE_COUNT 32

#define SAMPLE_DISTRIBUTION 2
// 0: LINEAR (r)
// 1: SQUARE (r^2), more prone to banding based on SSAO algorithm
// 2: LINEAR SQUARE HALFWAY (r * 0.5 + r^2 * 0.5 (but normalized))

// (re)distribution function (by radius)
float RadiusFunction(float r)
{
	float rmin = 0.05; // minimum radius
	float rmax = 1.00; // maximum radius
	
	#if SAMPLE_DISTRIBUTION == 0
		// r = r; // linear
	#elif SAMPLE_DISTRIBUTION == 1
		r = r * r; // square
	#elif SAMPLE_DISTRIBUTION == 2
		r = r * (r + 0.5f) * (2.0f / 3.0f); // linear + square halfway, normalized
	#else
		printf("error: no / invalid sample distribution chosen");
		exit(1);
	#endif
	
	return rmin + (rmax - rmin) * r;
}

// generate low discrepancy sampling kernel for ssao
// distribution is roughly uniform in a hemisphere (z+)
// the algorithm discards samples based on their position which may result in an infinite loop with bad parameters (I don't think it's possible, though)
//
// out: xyzw-point array [ x0, y0, z0, w0, x1, y1, z1, w1, ... xn, yn, zn, wn ]
// w: occlusion factor of the sample
void GenSamples(float * out, int count)
{
	// ---- parameters
	
	float radius = 1.0f;
	float z_shift = 0.05f * radius; // bias into the z-direction
	
	int base[3]; // base used for the halton sequence (index = axis). it seems prime numbers give fairly good "randomness" while other integers cause patterns to emerge.
	base[0] = 3;
	base[1] = 7;
	base[2] = 5;
	
	int offset[3]; // shifting of the halton sequences (index = axis). only positive integers allowed. I didn't use this but it may be helpful if variations are required.
	offset[0] = 0;
	offset[1] = 0;
	offset[2] = 0;
	
	// ----
	
	// generate points
	float cx = 0, cy = 0; // used to calculate center point
	int i, j, k = 1;
	for(i = 0; i < count; k++) // all points
	{
		// generate halton sequence for each axis
		for(j = 0; j < 3; j++) // all axes
		{
			// a basic halton sequence algorithm
			int _i = k + offset[j];
			
			float _f = 1;
			float _r = 0;
			
			while(_i > 0)
			{
				_f = _f / base[j];
				_r = _r + _f * (_i % base[j]);
				_i = floor(_i / base[j]);
			}
			
			// but remap to [-1; 1]
			out[i * 4 + j] = _r * 2.0f - 1.0f;
		}
		
		// volume check (hemisphere)
		float l2 = out[i * 4] * out[i * 4] + out[i * 4 + 1] * out[i * 4 + 1] + out[i * 4 + 2] * out[i * 4 + 2];
		if(l2 > 1.0f || out[i * 4 + 2] < 0)
		{
			continue; // sample invalid, discard
		}
		else
		{
			// sample valid
			cx += out[i * 4];
			cy += out[i * 4 + 1];
			i++;
		}
	}
	
	// agerage center (xy only because of hemisphere)
	cx /= count;
	cy /= count;
	
	// re-center
	float l2max = 0;
	for(i = 0; i < count; i++)
	{
		out[i * 4] -= cx;
		out[i * 4 + 1] -= cy;
		
		float l2 = out[i * 4] * out[i * 4] + out[i * 4 + 1] * out[i * 4 + 1] + out[i * 4 + 2] * out[i * 4 + 2];
		
		if(l2 > l2max)
		{
			l2max = l2;
		}
	}
	
	// apply radius function, normalize & add z bias
	// + calculate occlusion weight
	float normlen = 1.0f / sqrt(l2max); // length normalize factor
	for(i = 0; i < count; i++)
	{
		out[i * 4] *= normlen;
		out[i * 4 + 1] *= normlen;
		out[i * 4 + 2] *= normlen;
		
		float l = sqrt(out[i * 4] * out[i * 4] + out[i * 4 + 1] * out[i * 4 + 1] + out[i * 4 + 2] * out[i * 4 + 2]);
		
		out[i * 4] *= RadiusFunction(l) / l * radius;
		out[i * 4 + 1] *= RadiusFunction(l) / l * radius;
		out[i * 4 + 2] *= RadiusFunction(l) / l * radius;
		
		out[i * 4 + 2] += z_shift;
	}
}

int main(int argc, char * argv[])
{
	float * samples = (float*)malloc(sizeof(float) * SAMPLE_COUNT * 3);
	
	GenSamples(samples, SAMPLE_COUNT);
	
	// print with formatting
	printf("const float4 samples[%d] =\n{\n", SAMPLE_COUNT);
	
	int i;
	for(i = 0; i < SAMPLE_COUNT; i++)
	{
		printf("\tfloat4(% ff, % ff, %ff, %ff)", samples[i * 4], samples[i * 4 + 1], samples[i * 4 + 2], samples[i * 4 + 3]);
		printf((i == SAMPLE_COUNT - 1) ? "\n" : ",\n");
	}
	
	printf("};");
	
	fflush(stdout);
	
	free(samples);
	
	return 0;
}