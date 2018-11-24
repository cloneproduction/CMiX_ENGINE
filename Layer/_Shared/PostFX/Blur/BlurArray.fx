

Texture2DArray tex0;

float2 R:TARGETSIZE;
#include "ColorSpace.fxh"

SamplerState s0<string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Mirror;
    AddressV = Mirror;
};

SamplerState s1<string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
//StructuredBuffer<float4x4> sbWorld;
//StructuredBuffer<float4x4> tTex;
//StructuredBuffer<float> Width;
//StructuredBuffer<int> InstanceStartIndex;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : LAYERVIEWPROJECTION;
	float4x4 tW : WORLD;
	float4x4 tTex;
	float Width;
	float Saturation;
	float Contrast;
	float Brightness;
	int InstanceStartIndex;
	int SampAdress;

};

struct VS_IN
{
	//uint ii : SV_InstanceID;
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;
};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;	
    float4 TexCd: TEXCOORD0;
	//uint iid: TEXCOORD2;
};

vs2ps VS(VS_IN input)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
	
	//float4x4 w = sbWorld[input.ii];
	//float4x4 t = tTex[input.ii];
	//w=mul(w,tW);
    Out.PosWVP  = mul(input.PosO,mul(tW,tVP));
	//Out.iid = input.ii;
    Out.TexCd = mul(input.TexCd, tTex);
    return Out;
}

float3 safenormalize(float3 x){
		x=lerp(x,x+.00001,x==0);
		return normalize(x);
}

float4 PS_Tex(vs2ps In): SV_Target
{
	int id = InstanceStartIndex;
	float2 x = In.TexCd.xy;

    float lod=log2(max(R.x,R.y));
	lod=(Width)*log2(max(R.x,R.y));
	float4 c=0;
	float2 off=.5/R*pow(2,lod)*saturate(lod);
	
	if(SampAdress == 0){
		c+=tex0.SampleLevel(s0,float3(x+float2(0,0)*off, id ),lod);
		c+=tex0.SampleLevel(s0,float3(x+float2(1,1)*off, id),lod);
		c+=tex0.SampleLevel(s0,float3(x+float2(1,-1)*off, id),lod);
		c+=tex0.SampleLevel(s0,float3(x+float2(-1,-1)*off, id),lod);
		c+=tex0.SampleLevel(s0,float3(x+float2(-1,1)*off, id),lod);
		off*=1.86;
		c+=tex0.SampleLevel(s0,float3(x+float2(0,1)*off, id),lod);
		c+=tex0.SampleLevel(s0,float3(x+float2(0,-1)*off, id),lod);
		c+=tex0.SampleLevel(s0,float3(x+float2(-1,0)*off, id),lod);
		c+=tex0.SampleLevel(s0,float3(x+float2(1,0)*off, id),lod);
	}
	else if (SampAdress == 1){
		c+=tex0.SampleLevel(s1,float3(x+float2(0,0)*off, id ),lod);
		c+=tex0.SampleLevel(s1,float3(x+float2(1,1)*off, id),lod);
		c+=tex0.SampleLevel(s1,float3(x+float2(1,-1)*off, id),lod);
		c+=tex0.SampleLevel(s1,float3(x+float2(-1,-1)*off, id),lod);
		c+=tex0.SampleLevel(s1,float3(x+float2(-1,1)*off, id),lod);
		off*=1.86;
		c+=tex0.SampleLevel(s1,float3(x+float2(0,1)*off, id),lod);
		c+=tex0.SampleLevel(s1,float3(x+float2(0,-1)*off, id),lod);
		c+=tex0.SampleLevel(s1,float3(x+float2(-1,0)*off, id),lod);
		c+=tex0.SampleLevel(s1,float3(x+float2(1,0)*off, id),lod);
	}

	c/=9;
	
	/*float3 k = RGBtoHSL(c.rgb);
	float3 h=RGBtoHSV(c.rgb);
    //h.x=(frac(h.x+Hue))*HueCycles;
    h.y=h.y*Saturation;
    c.rgb=HSLtoRGB(h);
	float3 k0=HSVtoRGB(float3((frac(h.x)-0),h.y,h.z));
	float3 k1=HSVtoRGB(float3((frac(h.x)-1),h.y,h.z));
	c.rgb=lerp(k0,k1,pow(smoothstep(0,1,h.x),2));
    c.rgb=c.rgb*sqrt(3)*pow(length(c.rgb)/sqrt(3),pow(2,Contrast))*pow(2,Brightness);*/


    return c;
}

technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS_Tex() ) );
	}
}




