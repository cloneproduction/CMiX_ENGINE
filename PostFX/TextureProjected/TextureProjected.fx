//Texture2D texture2d <string uiname="Texture";>;

Texture2DArray texArray;
Texture2DArray texture2d  <string uiname="Texture";>;

SamplerState g_samLinear <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Mirror;
    AddressV = Mirror;
};

StructuredBuffer< float4x4> sbWorld;
StructuredBuffer<float4> sbColor;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
	float4x4 tW : WORLD;
	int colorcount = 1;
	int texcount = 1;
};

cbuffer cbPerObj : register( b1 )
{
	float Alpha <float uimin=0.0; float uimax=1.0;> = 1; 
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
	float4x4 tMsk <string uiname="Mask Transform"; bool uvspace=true; >;
	float4x4 tColor <string uiname="Color Transform";>;
};

struct VS_IN
{
	uint ii : SV_InstanceID;
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;
};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
    float4 TexCd: TEXCOORD0;
	float4 MskCd: TEXCOORD1;
	float4 Color: TEXCOORD2;
	uint ID: TEXCOORD3;
};

vs2ps VSMask(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
	float4x4 w = sbWorld[input.ii];
	w=mul(w,tW);
    Out.PosWVP  = mul(input.PosO,mul(w,tVP));
	Out.Color = sbColor[input.ii % colorcount];
    Out.TexCd = mul(Out.PosWVP, tTex);
	Out.MskCd = mul(input.TexCd, tMsk);
	Out.ID = input.ii%texcount;
    return Out;
}

vs2ps VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
    Out.PosWVP  = mul(input.PosO,mul(tW,tVP));
    Out.TexCd = mul(input.TexCd, tTex);
	Out.MskCd = mul(input.TexCd, tMsk);
	Out.ID = input.ii%texcount;
    return Out;
}

float4 PSMask(vs2ps In): SV_Target
{
    float4 col = texture2d.Sample(g_samLinear,float3(In.TexCd.xy/In.TexCd.w, In.ID)) * cAmb;
	float4 mask = texArray.Sample(g_samLinear,float3(In.MskCd.xy, In.ID));
	float amount = dot(0.33, mask);
	col = mul(col, tColor)*amount;
	col.a = mask.a;
    return col;
}

float4 PS(vs2ps In): SV_Target
{
    float4 col = texture2d.Sample(g_samLinear,float3(In.TexCd.xy, In.ID)) * cAmb;
	col = mul(col, tColor);
	col.a *= Alpha;
    return col;
}

technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}

technique10 Mask
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VSMask() ) );
		SetPixelShader( CompileShader( ps_4_0, PSMask() ) );
	}
}




