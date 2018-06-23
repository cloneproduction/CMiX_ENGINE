Texture2DArray texArray;
Texture2DArray maskArray;
Texture2DArray ControlTexture <string uiname="Control";>;

StructuredBuffer<uint> texarrayID;
StructuredBuffer<uint> mskarrayID;
StructuredBuffer< float4x4> sbWorld;

StructuredBuffer< float4x4> gsfxTransformTex;
StructuredBuffer<uint> MskOn;
StructuredBuffer<uint> KeepOriginal;
StructuredBuffer<float4> Amb;

StructuredBuffer<float>Saturation;
StructuredBuffer<float>Contrast;
StructuredBuffer<float>Brightness;
StructuredBuffer<float>Invert;

StructuredBuffer<float>ExplodeAmount;


int InstanceStartIndex = 0;

#include "ColorSpace.fxh"
#include "PhongDirectional.fxh"

float3 safenormalize(float3 x)
{
	x=lerp(x,x+.00001,x==0);
	return normalize(x);
}

SamplerState g_samLinear <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Mirror;
    AddressV = Mirror;
};

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
	float4x4 tV : VIEW;
	float4x4 tP : PROJECTION;
	float4x4 tWV : WORLDVIEW;
	float4x4 tW : WORLD;
	float4x4 tWIT: WORLDLAYERINVERSETRANSPOSE;
	float Hue=0;
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
};

struct VS_IN
{
	uint ii : SV_InstanceID;
	float4 PosO : POSITION;
	float3 NormO: NORMAL;
	float4 TexCd : TEXCOORD0;
};

struct vs2ps
{
    float4 Pos: SV_POSITION;
    float4 TexCd: TEXCOORD0;
	float4 MskCd: TEXCOORD1;
	uint iid: TEXCOORD2;
};

struct vs2psVisual
{
    float4 Pos: SV_POSITION;
    float4 TexCd: TEXCOORD0;
	float4 MskCd: TEXCOORD1;
	uint iid: TEXCOORD2;
	float3 LightDirV: TEXCOORD3;
    float3 NormV: TEXCOORD4;
    float3 ViewDirV: TEXCOORD5;
	float4 Color : TEXCOORD6;

};

vs2psVisual VS(VS_IN input)
{
    vs2psVisual Out = (vs2psVisual)0;

	//inverse light direction in view space
    Out.LightDirV = normalize(-mul(float4(lDir,0.0f), mul(tW,tV)).xyz);
    
    //normal in view space
    Out.NormV = normalize(mul(mul(input.NormO, (float3x3)tWIT),(float3x3)tV).xyz);

	Out.Pos = input.PosO;
    Out.TexCd = input.TexCd;
	Out.iid = input.ii;
	Out.Color = Amb[input.ii];
    return Out;
}

vs2ps VSMask(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
	float4x4 wo = sbWorld[input.ii + InstanceStartIndex];
	wo=mul(wo,tW);
	float4x4 wv = mul(wo, tV);
	float4 PosV = mul(input.PosO, wv);
	Out.Pos = mul(PosV, tP);
	
	if(MskOn[input.ii + InstanceStartIndex] == 1)
	{
	    Out.TexCd = mul(Out.Pos, tTex);
	}
	else
	{
	    Out.TexCd = input.TexCd;
	}
	
	Out.MskCd = input.TexCd;
	Out.iid = input.ii;
	return Out;
}

[maxvertexcount(3)]
void GS(triangle vs2psVisual input[3], inout TriangleStream<vs2psVisual> gsout)
{
	vs2psVisual elem = (vs2psVisual)0;

	float3 p1 = input[0].Pos.xyz;
	float3 p2 = input[1].Pos.xyz;
	float3 p3 = input[2].Pos.xyz;

	float3 faceEdgeA = p2 - p1;
    float3 faceEdgeB = p1 - p3;
    float3 norm = cross(faceEdgeB, faceEdgeA);
	norm = normalize(norm);	
	
	float3 col0 = ControlTexture.SampleLevel(g_samLinear, float3(mul(input[0].TexCd, gsfxTransformTex[input[0].iid + InstanceStartIndex]).xy, 0), 0).xyz;
	float3 col1 = ControlTexture.SampleLevel(g_samLinear, float3(mul(input[1].TexCd, gsfxTransformTex[input[1].iid + InstanceStartIndex]).xy, 0), 0).xyz;
	float3 col2 = ControlTexture.SampleLevel(g_samLinear, float3(mul(input[2].TexCd, gsfxTransformTex[input[2].iid + InstanceStartIndex]).xy, 0), 0).xyz;
	
	float amt = 1-(dot(col0, 0.33) + dot(col1, 0.33) + dot(col2, 0.33))/3;

	[unroll]
	for(int i = 0; i < 3; i++)
	{
		int id = input[i].iid + InstanceStartIndex;
		float4x4 wo = sbWorld[id];
		wo = mul(wo, tW);
		
		float4 position = float4(input[i].Pos.xyz+(norm*amt*ExplodeAmount[0]), input[i].Pos.w);
		elem.TexCd = input[i].TexCd;
		elem.Pos = mul(mul(position, wo), tVP);
		elem.ViewDirV = -normalize(mul(input[i].Pos, tWV).xyz);
		elem.NormV = normalize(mul(mul(input[i].NormV, (float3x3)tWIT),(float3x3)tV).xyz);
		elem.Color = Amb[id];
		elem.iid = input[i].iid;
		gsout.Append(elem);
	}
	
	gsout.RestartStrip();
}

float4 PS(vs2psVisual In): SV_Target
{
	int id = In.iid + InstanceStartIndex;
	
	float4 c = texArray.Sample(g_samLinear, float3(In.TexCd.xy, texarrayID[id]));

	c.rgb=lerp(c.rgb,1-c.rgb,Invert[id]);
	
	float3 h=RGBtoHSV(c.rgb);
    //h.x=(frac(h.x+Hue))*HueCycles;
    h.y=h.y*Saturation[id];
    c.rgb=HSLtoRGB(h);
	float3 k0=HSVtoRGB(float3((frac(h.x)-0),h.y,h.z));
	float3 k1=HSVtoRGB(float3((frac(h.x)-1),h.y,h.z));
	c.rgb=lerp(k0,k1,pow(smoothstep(0,1,h.x),2));
    c.rgb=safenormalize(c.rgb)*sqrt(3)*pow(length(c.rgb)/sqrt(3),pow(2,Contrast[id]))*pow(2,Brightness[id]);
	c.rgb *= In.Color.rgb;
	c.rgb *= PhongDirectional(In.NormV, In.ViewDirV, lDir).xyz;
	return c;
}


float4 PSMask(vs2ps In): SV_Target
{
	int id = In.iid + InstanceStartIndex;
	
	float4 col = texArray.Sample(g_samLinear,float3(In.TexCd.xy/In.TexCd.w, texarrayID[id]));

	///INVERT///
	float4 inv = 1;
	inv.rgb=lerp(col.rgb,1-col.rgb,Invert[id]);
	inv.a = col.a;

	if(MskOn[id] == 1)
	{
		float4 mask = maskArray.Sample(g_samLinear,float3(In.MskCd.xy, mskarrayID[id]));
		float amount = dot(0.33, mask.rgb);
		
		if(KeepOriginal[id] == 1)
		{
			col = lerp (col, inv, mask.a);
		}
		else
		{
			col = inv;
			col.a =  mask.a * inv.a;	
		}
	}
	return col;
}

technique10 Visual
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader ( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS() ) );
	}
}

technique10 Mask
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VSMask() ) );
		//SetGeometryShader ( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_4_0, PSMask() ) );
	}
}




