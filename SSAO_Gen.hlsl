
// ---- SETTINGS

#define SSAO_RADIUS_UNITS 0.5f // radius in world units
#define CAMERA_VFOV 0.88f // vertical fov of the camera in radians
#define SSAO_RADIUS (tan(CAMERA_VFOV / 2.0f) * SSAO_RADIUS_UNITS) // precalculate this an pass it to the shader instead

#define SSAO_RADIUS_LIMIT 0.125f // radius limit of the ssao kernel as screen percentage (% of screen height)

#define SSAO_SAMPLES 6 // number of samples for ssao; int (1 to 16), no internal range check!

// internal settings
#define VIEWPORT_SIZE float2(1280.0f, 720.0f) // pass this to the shader
#define PIXEL_SIZE (1.0f / VIEWPORT_SIZE)

#define SURFACE_THICKNESS float3(SSAO_RADIUS * 0.05f, SSAO_RADIUS * 2.0f, SSAO_RADIUS) // assumed thickness of objects; x: fade-in distance, x: thickness (fully occluded), y: fade-out distance

// ---- INTERFACING

Texture2D texDepth; // depth buffer
Texture2D texNormal; // normal buffer

SamplerState smpPoint; // sampler with point filter (nearest neighbour), address = clamp

// get linear depth from depth buffer
//   uv: uv coordinate to sample
//   return: linear depth value in world units
float GetLinearDepth(float2 uv)
{
	// transform to linear depth here if neccessary!
	return texDepth.Sample(smpPoint, uv).x;
}

// get viewspace normal: (0, 0, 1) always points "towards" camera
//   uv: uv coordinate to sample
//   return: (unit) normal vector in viewspace
float3 GetViewspaceNormal(float2 uv)
{
	// depends on implementation; here: get xy from texture (R16G16 signed), calculate z
	float2 xy = texNormal.Sample(smpPoint, uv).xy * 2.0f - 1.0f;
	return float3(xy, sqrt(1.0f - xy.x * xy.x - xy.y * xy.y));
}

// ----

// get ssao radius
//   depth: linear depth value of the pixel
float GetSSAORadius(float depth)
{
	return SSAO_RADIUS;
}

// limit radius to a max screen percentage
//   radiusPx: radius in pixels
//   returns: new radius in pixels
float2 LimitSSAORadius(float2 radiusPx)
{
	const float maxRadius = SSAO_RADIUS_LIMIT / VIEWPORT_SIZE.y;
	return min(radius, maxRadius);
}

// calculates how much a sample should be weighted
//   refDepth: reference depth value
//   depth: sample depth
float GetSampleWeight(float refDepth, float depth)
{
	
}

// calculates how much occlusion a single sample causes
//   refDepth: reference depth value
//   depth: sample depth
float GetSampleOcclusion(float refDepth, float depth)
{
	float occlusion = depth - 
	
	
}

// gets a sample of the precalculated kernel
//   index: must be in rage [0; 31]
float3 GetKernelSample(int index)
{
	const float3 kernel[32] = // precalculated hemisphere kernel (low discrepancy noiser)
	{
		float3(-0.668154f, -0.084296f, 0.219458f),
		float3(-0.092521f,  0.141327f, 0.505343f),
		float3(-0.041960f,  0.700333f, 0.365754f),
		float3( 0.722389f, -0.015338f, 0.084357f),
		float3(-0.815016f,  0.253065f, 0.465702f),
		float3( 0.018993f, -0.397084f, 0.136878f),
		float3( 0.617953f, -0.234334f, 0.513754f),
		float3(-0.281008f, -0.697906f, 0.240010f),
		float3( 0.303332f, -0.443484f, 0.588136f),
		float3(-0.477513f,  0.559972f, 0.310942f),
		float3( 0.307240f,  0.076276f, 0.324207f),
		float3(-0.404343f, -0.615461f, 0.098425f),
		float3( 0.152483f, -0.326314f, 0.399277f),
		float3( 0.435708f,  0.630501f, 0.169620f),
		float3( 0.878907f,  0.179609f, 0.266964f),
		float3(-0.049752f, -0.232228f, 0.264012f),
		float3( 0.537254f, -0.047783f, 0.693834f),
		float3( 0.001000f,  0.177300f, 0.096643f),
		float3( 0.626400f,  0.524401f, 0.492467f),
		float3(-0.708714f, -0.223893f, 0.182458f),
		float3(-0.106760f,  0.020965f, 0.451976f),
		float3(-0.285181f, -0.388014f, 0.241756f),
		float3( 0.241154f, -0.174978f, 0.574671f),
		float3(-0.405747f,  0.080275f, 0.055816f),
		float3( 0.079375f,  0.289697f, 0.348373f),
		float3( 0.298047f, -0.309351f, 0.114787f),
		float3(-0.616434f, -0.117369f, 0.475924f),
		float3(-0.035249f,  0.134591f, 0.840251f),
		float3( 0.175849f,  0.971033f, 0.211778f),
		float3( 0.024805f,  0.348056f, 0.240006f),
		float3(-0.267123f,  0.204885f, 0.688595f),
		float3(-0.077639f, -0.753205f, 0.070938f)
	};
	
	return kernel[index];
}

// returns how much a sample is influencing the ao value based on its radius from the kernel center
// to improve performance you can also return 1.0f for all samples
float GetSampleInfluence(float radius)
{
	//return 1.0f; // weight all samples the same: less "accurate" but faster
	
	// de-transform radius (this depends on how samples were generated)
	// more correct but has almost no visible effect => probably leave it off
	//r = 0.25f * sqrt(24.0f * r + 1.0f) - 0.25f; 
	
	const float pi = 3.14159265f;
	float density = 2.0f * pi * pow(smpcount, 2.0f / 3.0f) * (r * r) + pi / 6.0f; // expected sample density on this hemisphere (at redius r)
	
	return 1.0f / density;
}

float CalculateSSAO(float2 uv)
{
	float2 pixel = float2(1.0f, 1.0f) / VIEWPORT_SIZE; // pixel size
	
	// setup dither patterns
	int2 uvpx = int2(In.Position.xy); // pixel position as integer
	int2 pixelIndex;
	pixelIndex.x = int((uvpx.x + uvpx.y) / 2) % 2; // small checkerboard (2x2) [0 ... 1]
	pixelIndex.y = (uvpx.x % 2 + (uvpx.y % 2) * 2) % 4; // small spiral (2x2) [0 ... 3]
	
	// construct rotation matrix
	float3 normal = GetViewspaceNormal(uv);
	
	float3 randomVec = float3(kernel[pixelIndex.y].xyz);
	float3 tangent = cross(randomVec, normal);
	float3 bitangent = cross(normal, tangent);
	float3x3 tbn = float3x3(tangent, bitangent, normal);
}
