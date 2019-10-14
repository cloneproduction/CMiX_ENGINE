Texture2DArray ControlTexture <string uiname="Control";>;
Texture2D tex;

StructuredBuffer< float4x4> TexTransform;
StructuredBuffer< float4x4> gsfxTransformTex;
StructuredBuffer<float4> Amb;
StructuredBuffer<float>Hue;
float Saturation;
StructuredBuffer<float>Luminosity;
StructuredBuffer<float>Contrast;
StructuredBuffer<float>Brightness;
StructuredBuffer<float>Invert;
StructuredBuffer<uint> InvertMode;
StructuredBuffer<float>Keying;
StructuredBuffer<float>ExplodeAmount;

#include "ColorSpace.fxh"

float Map (float value, float low1, float high1,float low2, float high2)
{
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

SamplerState g_samLinear <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Mirror;
    AddressV = Mirror;
};

StructuredBuffer<float4x4> ObjPosOriginal;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;
	float4x4 tV : VIEW;
	float4x4 tP : PROJECTION;
	float4x4 tWV : WORLDVIEW;
	float4x4 tW : WORLD;
	float4x4 tWIT: WORLDLAYERINVERSETRANSPOSE;
	int InstanceStartIndex = 0;
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
	float4x4 ObjTransform;
	float4x4 GroupTransform;
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

		float4x4 InstancePos = mul(ObjPosOriginal[id], GroupTransform);
		float4 ObjPos = mul(input[i].Pos, ObjTransform);
		float4 NewPosition = mul(ObjPos, InstancePos);

		float4 position = float4(NewPosition.xyz+(norm*amt*ExplodeAmount[id]), NewPosition.w);
		
		float3 LightDirV = normalize(-mul(float4(lDir,0.0f), tV).xyz);
	
	    //normal in view space
	    float3 NormV = normalize(mul(mul(mul(input[i].NormV.xyz, tW), tWIT),tV)).xyz;
		
	    //view direction = inverse vertexposition in viewspace
	    float4 PosV = mul(mul(position, tW), tWV);
	    float3 ViewDirV = normalize(-PosV.xyz);
	
	    //halfvector
	    float3 H = normalize(ViewDirV + LightDirV);
	
	    //compute blinn lighting
	    float3 shades = lit(dot(NormV, LightDirV), dot(NormV, H), lPower).xyz;
	    float4 diff = lDiff * shades.y;
	    float4 spec = lSpec * shades.z;
		
		//elem.Pos = mul(mul(position, wo), tVP);
		elem.Pos = mul(position, mul(tW, tVP));
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

	float2 uv = mul(float4((In.TexCd.xy*2-1)*float2(1,-1)*.5,0,1),TexTransform[id]).xy*float2(1,-1)+0.5;
	float4 c = tex.SampleLevel(g_samLinear, uv, 0);

	float3 grey = dot(c.rgb, float3(0.3, 0.59, 0.11));
	c.rgb = lerp(c.rgb, grey, Map(Saturation, -1.0, 1.0, 1.0, -1.0));
	float3 hsv = RGBtoHSL(c.rgb);
	
	hsv.r += Hue[id];
	//hsv.g *= Saturation[id];
	hsv.b += Luminosity[id];
	c.rgb = HSLtoRGB(hsv.rgb);
	
	c.rgb = ((c.rgb - 0.5f) * max(Contrast[id]*4.0 + 1.0, 0)) + 0.5f;
	c.rgb += Brightness[id]*2.0;

	if(InvertMode[id] == 0)
	{
		/// INVERT RGB ///
		c.rgb=lerp(c.rgb,1-c.rgb,Invert[id]);
	}
	else if (InvertMode[id] == 1)
	{
		/// INVERT LUMA ///
		hsv.z = lerp(hsv.z, clamp(0, 1, 1-hsv.z),Invert[id]);
		c.rgb = HSVtoRGB(hsv);
	}
	
	c.rgb = c.rgb * In.Color.rgb;
	c.rgb = c.rgb* (In.Diffuse.xyz + In.Specular.xyz);
	
	c.a = lerp(c.a, hsv.z , Keying[id]);
	
	return c;
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