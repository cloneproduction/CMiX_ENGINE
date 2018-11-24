
Texture2DArray ControlTexture <string uiname="Control";>;

Texture2D tex;

StructuredBuffer< float4x4> sbWorld;

StructuredBuffer< float4x4> gsfxTransformTex;

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

float4x4 brightnessMatrix (float brightness)
{
	return float4x4(1, 0, 0, 0,
					0, 1, 0, 0,
					0, 0, 1, 0,
					brightness, brightness, brightness, 1);
}

float4x4 contrastMatrix (float contrast)
{
	float t = ( 1.0 - contrast) / 2.0;
	return float4x4 ( contrast, 0, 0, 0,
                 	0, contrast, 0, 0,
                 	0, 0, contrast, 0,
                 	t, t, t, 1 );
}


float4x4 saturationMatrix( float saturation )
{
    float3 luminance = float3( 0.3086, 0.6094, 0.0820 );
    
    float oneMinusSat = 1.0 - saturation;
    
    float3 red = float3( luminance.x * oneMinusSat, luminance.x * oneMinusSat, luminance.x * oneMinusSat );
    red+= float3( saturation, 0, 0 );
    
    float3 green = float3( luminance.y * oneMinusSat, luminance.y * oneMinusSat, luminance.y * oneMinusSat );
    green += float3( 0, saturation, 0 );
    
    float3 blue = float3( luminance.z * oneMinusSat, luminance.z * oneMinusSat, luminance.z * oneMinusSat );
    blue += float3( 0, 0, saturation );
    
    return float4x4( red,     0,
                 green,   0,
                 blue,    0,
                 0, 0, 0, 1 );
}

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

	float4 c = tex.SampleLevel(g_samLinear, In.TexCd.xy, 0);

	
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
	
	c = mul(c, mul(saturationMatrix(Saturation[id]), mul(contrastMatrix(Contrast[id]), brightnessMatrix(Brightness[id]))));

	
	float3 k = RGBtoHSL(c.rgb);

	c.rgb = saturate(c.rgb * In.Color.rgb);
	c.rgb = saturate(c.rgb* (In.Diffuse.xyz + In.Specular.xyz));
	c.a = lerp(c.a, k.z , Keying[id]);
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




