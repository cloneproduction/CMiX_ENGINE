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
StructuredBuffer<float>Keying;
StructuredBuffer<uint> InvertMode;

StructuredBuffer<float>ExplodeAmount;

int InstanceStartIndex = 0;

#include "ColorSpace.fxh"
//#include "PhongDirectional.fxh"

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

cbuffer cbLightData : register(b3)
{
	float3 lDir <string uiname="Light Direction";> = {0, -5, 2}; 
	float4 lAmb  <bool color=true; String uiname="Ambient Color";>  = {0.15, 0.15, 0.15, 1};
	float4 lDiff <bool color=true;String uiname="Diffuse Color";>  = {0.85, 0.85, 0.85, 1};
	float4 lSpec <bool color=true; String uiname="Specular Color";> = {0.35, 0.35, 0.35, 1};
	float lPower <String uiname="Power"; float uimin=3.0;> = 25.0;     	
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
	float4 Diffuse: COLOR0;
    float4 Specular: COLOR1;

};

vs2psVisual VS(VS_IN input)
{
    vs2psVisual Out = (vs2psVisual)0;
	
	Out.Pos = input.PosO;
    Out.TexCd = input.TexCd;
	Out.NormV = input.NormO;
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
	
		float4 position = float4(input[i].Pos.xyz+(norm*amt*ExplodeAmount[id]), input[i].Pos.w);
			
		float3 LightDirV = normalize(-mul(float4(lDir,0.0f), tV).xyz);
	
	    //normal in view space
	    float3 NormV = normalize(mul(mul(mul(input[i].NormV.xyz, wo), (float3x3)tWIT),(float3x3)tV).xyz);
		
	    //view direction = inverse vertexposition in viewspace
	    float4 PosV = mul(mul(position, wo), tWV);
	    float3 ViewDirV = normalize(-PosV.xyz);
	
	    //halfvector
	    float3 H = normalize(ViewDirV + LightDirV);
	
	    //compute blinn lighting
	    float3 shades = lit(dot(NormV, LightDirV), dot(NormV, H), lPower).xyz;
	
	    float4 diff = lDiff * shades.y;
	    float4 spec = lSpec * shades.z;
		
		elem.Pos = mul(mul(position, wo), tVP);
		elem.Diffuse = diff + lAmb;
	    elem.Specular = spec;
		elem.TexCd = input[i].TexCd;
		elem.Color = Amb[id];
		elem.iid = input[i].iid;
		
		gsout.Append(elem);
	}
	
	gsout.RestartStrip();
}

float4 PS(vs2psVisual In): SV_Target
{
	int id = In.iid + InstanceStartIndex;
	
	float4 c = texArray.SampleLevel(g_samLinear, float3(In.TexCd.xy, texarrayID[id]), 0);

	
	if(InvertMode[id] == 0)
	{
		/// INVERT RGB ///
		c.rgb=lerp(c.rgb,1-c.rgb,Invert[id]);
	}
	else if (InvertMode[id] == 1)
	{
		/// INVERT LUMA ///
		float3 hsv = RGBtoHSV(c.rgb);
		hsv.z = lerp(hsv.z, clamp(0, 1, 1-hsv.z),Invert[id]);
		c.rgb = HSVtoRGB(hsv);
	}
		float3 k = RGBtoHSL(c.rgb);
	
	float3 h=RGBtoHSV(c.rgb);
    //h.x=(frac(h.x+Hue))*HueCycles;
    h.y=h.y*Saturation[id];
    c.rgb=HSLtoRGB(h);
	float3 k0=HSVtoRGB(float3((frac(h.x)-0),h.y,h.z));
	float3 k1=HSVtoRGB(float3((frac(h.x)-1),h.y,h.z));
	c.rgb=lerp(k0,k1,pow(smoothstep(0,1,h.x),2));
    c.rgb=safenormalize(c.rgb)*sqrt(3)*pow(length(c.rgb)/sqrt(3),pow(2,Contrast[id]))*pow(2,Brightness[id]);
	c.rgb *= In.Color.rgb;
	
	c.rgb *= In.Diffuse.xyz + In.Specular.xyz;
	
	c.a = lerp(c.a, k.z, Keying[id]*10);
	return c;
}


float4 PSMask(vs2ps In): SV_Target
{
	int id = In.iid + InstanceStartIndex;
	
	float4 c = texArray.Sample(g_samLinear,float3(In.TexCd.xy/In.TexCd.w, texarrayID[id]));

	///INVERT///
	float4 originalcol = c;
	float4 modifcol = c;
	
	if(MskOn[id] == 1)
	{
		float4 mask = maskArray.Sample(g_samLinear,float3(In.MskCd.xy, mskarrayID[id]));
		modifcol.a *=  mask.a;
		
		float3 h=RGBtoHSV(modifcol.rgb);
	    //h.x=(frac(h.x+Hue))*HueCycles;

	    h.y=h.y*Saturation[id];
	    //modifcol.rgb=HSLtoRGB(h);
		float3 k0=HSVtoRGB(float3((frac(h.x)-0),h.y,h.z));
		float3 k1=HSVtoRGB(float3((frac(h.x)-1),h.y,h.z));
		modifcol.rgb=lerp(k0,k1,pow(smoothstep(0,1,h.x),2));
	    modifcol.rgb=safenormalize(modifcol.rgb)*sqrt(3)*pow(length(modifcol.rgb)/sqrt(3),pow(2,Contrast[id]))*pow(2,Brightness[id]);

		if(InvertMode[id] == 0) 		// INVERT RGB
		{
			modifcol.rgb = lerp(modifcol.rgb,1-modifcol.rgb,Invert[id]);
		}
		else if (InvertMode[id] == 1)   // INVERT LUMA
		{
			float3 hsv = RGBtoHSV(modifcol.rgb);
			hsv.z = lerp(hsv.z, clamp(0, 1, 1-hsv.z),Invert[id]);
			modifcol.rgb = HSVtoRGB(hsv);
		}
	}
	return modifcol;
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




