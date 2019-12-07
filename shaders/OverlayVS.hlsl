cbuffer cbPerFrame : register(b0)
{
	float2 viewport;
};

struct VSInput
{
	float3 Position : POSITION;
	float3 Normal : NORMAL;
	float2 UV : TEXCOORD0;
};

struct VSOutput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD0;
};

VSOutput main(in VSInput In)
{
	VSOutput Out = (VSOutput)0;
	
	static const float2 OverlaySize = float2(490.0f, 64.0f) * 2.0f;
	
	Out.Position.xyz = In.Position * 0.5f;
	Out.UV = Out.Position.xy + 0.5f;
	
	Out.Position.xy *= OverlaySize / viewport;
	Out.Position.y += 1.0f - OverlaySize.y / viewport.y * 0.5f;
	Out.Position.x -= 1.0f - OverlaySize.x / viewport.x * 0.5f;
	Out.Position.w = 1.0f;
	
	return Out;
}