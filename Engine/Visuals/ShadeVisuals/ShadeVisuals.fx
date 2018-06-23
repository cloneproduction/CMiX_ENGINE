#include "ColorSpace.fxh"

float4x4 tW : WORLD;
float4x4 tV : VIEW;
float4x4 tP : PROJECTION;
float4x4 tVP : VIEWPROJECTION;
float boost;
int InstanceStartIndex = 0;

StructuredBuffer<float4x4> world;
Texture2DArray texarray;

StructuredBuffer<uint> texarrayID;
StructuredBuffer<float4> Amb;
StructuredBuffer<float>Saturation;
StructuredBuffer<float>Contrast;
StructuredBuffer<float>Brightness;
StructuredBuffer<float>Invert;
StructuredBuffer<float>Boost;

Texture2D tex;
Texture2D ControlTexture <string uiname="Control";>;
SamplerState linearSampler <string uiname="Sampler State";>
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct VS_IN
{
	uint ii : SV_InstanceID;
    float4 PosO  : POSITION;
    float4 TexCd : TEXCOORD0;
};

struct vs2ps
{
    float4 pos: SV_POSITION;
    float4 TexCd: TEXCOORD0;
	uint iid : TEXCOORD1;
};

vs2ps VS(VS_IN input)
{
    vs2ps Out = (vs2ps)0;
	float4x4 wo = world[input.ii + InstanceStartIndex];
	wo = mul(wo,tW);	
	float4x4 wv = mul(wo,tV);
    float4 PosV = mul(input.PosO, wv);
	Out.pos = mul(input.PosO, wo);
    Out.TexCd = input.TexCd;
	Out.iid = input.ii;
    return Out;
}

[maxvertexcount(3)]
void GS(triangle vs2ps input[3], inout TriangleStream<vs2ps> gsout)
{
	vs2ps elem = (vs2ps)0;

	float3 p1 = input[0].pos.xyz;
	float3 p2 = input[1].pos.xyz;
	float3 p3 = input[2].pos.xyz;

	float3 faceEdgeA = p2 - p1;
    float3 faceEdgeB = p1 - p3;
    float3 norm = cross(faceEdgeB, faceEdgeA);
	norm = normalize(norm);	
	
	float4 col0 = ControlTexture.SampleLevel(linearSampler,input[0].TexCd.xy,0);
	float4 col1 = ControlTexture.SampleLevel(linearSampler,input[1].TexCd.xy,0);
	float4 col2 = ControlTexture.SampleLevel(linearSampler,input[2].TexCd.xy,0);
	
	float amt = (col0.r + col1.r + col2.r)/3;

	float4 position0 = float4(input[0].pos.xyz+(norm*amt*Boost[input[0].iid]), input[0].pos.w);
	elem.TexCd = input[0].TexCd;
	elem.pos = mul(position0, tVP);
	gsout.Append(elem);

	float4 position1 = float4(input[1].pos.xyz+(norm*amt*Boost[input[1].iid]), input[1].pos.w);
	elem.TexCd = input[1].TexCd;
	elem.pos = mul(position1, tVP);
	gsout.Append(elem);
	
	float4 position2 = float4(input[2].pos.xyz+(norm*amt*Boost[input[2].iid]), input[2].pos.w);
	elem.TexCd = input[2].TexCd;
	elem.pos = mul(position2, tVP);
	gsout.Append(elem);

	gsout.RestartStrip();
}

float3 safenormalize(float3 x){
		x=lerp(x,x+.00001,x==0);
		return normalize(x);
}

float4 PS(vs2ps In): SV_Target
{
	float4 c = texarray.Sample(linearSampler, float3(In.TexCd.xy, texarrayID[In.iid+ InstanceStartIndex]));
	float4 objcolor = tex.Sample(linearSampler,In.TexCd.xy);
	int id = In.iid+ InstanceStartIndex;

	c.rgb=lerp(c.rgb,1-c.rgb,Invert[id]);
	
	float3 h=RGBtoHSV(c.rgb);
   // h.x=(frac(h.x+Hue))*HueCycles;
    h.y=h.y*Saturation[id];
    c.rgb=HSLtoRGB(h);
	float3 k0=HSVtoRGB(float3((frac(h.x)-0),h.y,h.z));
	float3 k1=HSVtoRGB(float3((frac(h.x)-1),h.y,h.z));
	c.rgb=lerp(k0,k1,pow(smoothstep(0,1,h.x),2));
    c.rgb=safenormalize(c.rgb)*sqrt(3)*pow(length(c.rgb)/sqrt(3),pow(2,Contrast[id]))*pow(2,Brightness[id]);
	c.rgb  *= Amb[In.iid+ InstanceStartIndex].rgb;
	return c;
}

technique10 GouraudDirectional
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_5_0, VS() ) );
		SetGeometryShader ( CompileShader( gs_5_0, GS() ) );
		SetPixelShader( CompileShader( ps_5_0, PS() ) );
	}
}

