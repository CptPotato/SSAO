cbuffer cbPerFrame : register(b0)
{
	
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
	
	Out.Position.xyz = In.Position;
	Out.Position.w = 0.5f;
	Out.UV = Out.Position.xy + 0.5f;
	
	return Out;
}