Texture2D tex0 <string uiname="Texture";>;

SamplerState s0:IMMUTABLE{Filter=MIN_MAG_MIP_POINT;AddressU=WRAP;AddressV=WRAP;};

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
	float4x4 tP : PROJECTION;
	float4x4 tVI : VIEWINVERSE;
	float4x4 tV : VIEW;
};


struct VS_IN
{
	float4 PosO : POSITION;
	float2 UV : TEXCOORD0;
};

struct VS_OUT
{
    float4 PosWVP: SV_POSITION;
    float2 UV: TEXCOORD0;
};

VS_OUT VS(VS_IN In)
{
    VS_OUT Out = (VS_OUT)0;

    //position (projected)
	Out.PosWVP = In.PosO;//mul(In.PosO,mul(tW,tVP));
    Out.UV = In.UV;
    return Out;
}
float2 Reso:TARGETSIZE;
int pixSize=8;
StructuredBuffer<float4> sbInput;

float4 PS_PIX(VS_OUT In): SV_Target{
	float4 c=.1;
	int2 iuv=floor((In.UV*Reso+0.));
	c=sbInput[min(iuv,Reso).x+floor(iuv.y/(uint)pixSize)*Reso.x];
	c.a=1;
    return c;
}

technique10 Pixels
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_PIX() ) );
	}
}
