cbuffer cbPerFrame : register(b0)
{
	float2 viewport;
};

struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD0;
};

Texture2D texColor : register(t0);
SamplerState smp : register(s0);

float4 main(in PSInput In) : COLOR0
{
	if(In.UV.x > 1.0f || In.UV.y > 1.0f)
	{
		//clip(-1);
		//return float4(0.0f, 0.0f, 0.0f, 0.0f);
	}
	
	float4 color = texColor.Sample(smp, In.UV);
	
	return color;
}
