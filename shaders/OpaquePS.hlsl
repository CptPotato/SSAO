cbuffer cbPerFrame : register(b0)
{
	float4x4 matVP;
	float4x4 matGeo;
	float2 viewport;
	float2 mouse;
};

struct PSInput
{
	float4 Position : SV_POSITION;
	float4 NormalDepth : TEXCOODR0;
	float2 UV : TEXCOODR1;
};

struct PSOutput
{
	float4 Color : COLOR0; // main color target
	float2 Normal : COLOR1; // normal buffer
	float Depth : COLOR2; // depth buffer
};

Texture2D texAlbedo : register(t0);
SamplerState smp : register(s0);

PSOutput main(PSInput In)
{
	PSOutput Out = (PSOutput)0;
	
	float4 albedo = texAlbedo.Sample(smp, In.UV);
	
	float3 normal = normalize(In.NormalDepth.xyz);
	const float3 light = normalize(float3(1.0f, 5.0f, -3.0f));
	
	float3 directlight = max(dot(normal, light), 0.0f) * float3(1.8f, 1.4f, 1.0f);
	float3 ambient = (normal.y * 0.5f + 1.0f) * float3(0.2f, 0.24f, 0.3f);
	
	float3 color = albedo * (directlight + ambient);
	
	
	// Output
	const float exposure = 1.3f;
	Out.Color.rgb = saturate((1.0f - exp(-color * exposure)) * 1.05f); // simple tonemapping
	Out.Color.a = 1.0f;
	
	static const float2 OverlaySize = float2(490.0f, 64.0f);
	float2 mousepx = saturate(float2(mouse.x, 1.0f - mouse.y)) * viewport;
	if(mousepx.y < OverlaySize.y)
	{
		if(mousepx.x < OverlaySize.x * 0.5f)
		{
			Out.Color.rgb = normal.y * 0.25f + 0.6f;
		}
		else if(mousepx.x < OverlaySize.x)
		{
			Out.Color.rgb = 0.8f;
		}
	}
	
	Out.Normal = normalize(mul(float4(normal, 0.0f), matVP)).xy;
	
	Out.Depth = In.NormalDepth.w;
	
	return Out;
}
