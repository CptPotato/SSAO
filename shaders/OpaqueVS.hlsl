cbuffer cbPerFrame : register(b0)
{
	float4x4 matVP;
	float4x4 matGeo;
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
	float4 NormalDepth : TEXCOORD0;
	float2 UV : TEXCOORD1;
};

VSOutput main(VSInput In)
{
	VSOutput Out = (VSOutput)0;
	
	Out.Position = mul(mul(float4(In.Position, 1.0f), matGeo), matVP);

	Out.NormalDepth.xyz = mul(float4(In.Normal, 0.0f), matGeo).xyz;
	Out.NormalDepth.w = Out.Position.z;
	
	Out.UV = In.UV;
	
	return Out;
}