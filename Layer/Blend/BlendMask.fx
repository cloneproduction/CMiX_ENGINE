//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 
Texture2DArray Mask <string uiname="Mask";>;
Texture2DArray Content <string uiname="Content";>;
uint texarrayID;
bool EnableMask;

struct vsInput
{
    float4 posObject : POSITION;
};

struct psInput
{
    float4 posScreen : SV_Position;
};

struct vsInputTextured
{
    float4 posObject : POSITION;
	float4 uv: TEXCOORD0;
};

struct psInputTextured
{
    float4 posScreen : SV_Position;
    float4 uv: TEXCOORD0;
};

SamplerState linearSampler <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

cbuffer cbPerDraw : register(b0)
{
	float4x4 tVP : LAYERVIEWPROJECTION;
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	//float Alpha <float uimin=0.0; float uimax=1.0;> = 1; 
	//float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
	//float4x4 tColor <string uiname="Color Transform";>;
};

cbuffer cbTextureData : register(b2)
{
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
};

psInputTextured VS_Textured(vsInputTextured input)
{
	psInputTextured output;
	output.posScreen = mul(input.posObject,mul(tW,tVP));
	output.uv = mul(input.uv, tTex);
	return output;
}

float4 PS_Textured(psInputTextured input): SV_Target
{
	float4 c = Content.Sample(linearSampler,float3(input.uv.xy, texarrayID));
	float4 m;
	if(EnableMask == true)
	{
		m = Mask.Sample(linearSampler,float3(input.uv.xy, texarrayID));
		c.a *= m.a;
	}
	else{
		m = 1.0;
	}
	return c;
}

technique11 Constant <string noTexCdFallback="ConstantNoTexture"; >
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS_Textured() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Textured() ) );
	}
}





