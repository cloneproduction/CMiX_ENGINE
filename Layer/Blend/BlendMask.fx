Texture2DArray Mask <string uiname="Mask";>;
Texture2DArray Content <string uiname="Content";>;

uint texarrayID;

#include "ColorSpace.fxh"

bool EnableMask;
bool KeepOriginal;
uint MaskType;
uint ControlType;

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
};

cbuffer cbTextureData : register(b2)
{
	float4x4 tTex <string uiname="Texture Transform"; bool uvspace=true; >;
};

float4 Pixelate(Texture2DArray tex, SamplerState s0, float2 uv, float Fader)
{
	float pixels;
	float segment_progress;//= (Fader - 0.5) * 2;
	if (Fader < 0.5)
	{
		segment_progress = 1 - Fader * 2;
	}
	else
	{		
		segment_progress = (Fader - 0.5) * 2;
	}
    pixels = 20 ;
	float2 newUV = round(uv * pixels) / pixels;	
	float4 c1 = tex.Sample(linearSampler,float3(newUV, texarrayID));
	return c1;	
}

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
	
	if(EnableMask == true)
	{
		float4 m = Mask.Sample(linearSampler,float3(input.uv.xy, texarrayID));
		float maskcomponent;
		
		if(MaskType == 0) // Get Luminance
		{
			maskcomponent = dot(m.rgb, float3(0.3, 0.59, 0.11)).r;
		}
		else if(MaskType == 1) // Get Red
		{
			maskcomponent = m.r;
		}
		else if(MaskType == 2) // Get Green
		{
			maskcomponent = m.g;
		}
		else if(MaskType == 3) // Get Blue
		{
			maskcomponent = m.b;
		}
		else if(MaskType == 4) // Get Alpha
		{
			maskcomponent = m.a;
		}
		else if(MaskType == 5) // Get Invert Alpha
		{
			maskcomponent = 1-m.a;
		}
		else if(MaskType == 6) // Get Saturation
		{
			maskcomponent = RGBtoHSV(m.rgb).y;
		}
		else if(MaskType == 7) // Get Value
		{
			maskcomponent = RGBtoHSV(m.rgb).z;
		}
		
		
		if(ControlType == 0) // Control GreyScale
		{
			c.rgb = lerp(c.rgb, dot(c.rgb, float3(0.3, 0.59, 0.11)), maskcomponent);
		}
		else if(ControlType == 1) // Control Red
		{
			c.r *= maskcomponent;
		}
		else if(ControlType == 2) // Control Green
		{
			c.g *= maskcomponent;
		}
		else if(ControlType == 3) // Control Blue
		{
			c.b *= maskcomponent;
		}
		else if(ControlType == 4) // Control Alpha
		{
			c.a *= 1-maskcomponent;
		}
		else if(ControlType == 5) //Control InvertRGB
		{
			c.rgb = lerp(c.rgb, 1-c.rgb, maskcomponent);
		}
		else if(ControlType == 6) //Control InvertValue
		{
			float3 hsv = RGBtoHSV(c.rgb);
			hsv.z = lerp(hsv.z, 1-hsv.z, maskcomponent);
			c.rgb = HSVtoRGB(hsv);
		}
		else if(ControlType == 7) //Control Saturation
		{
			float3 hsv = RGBtoHSV(c.rgb);
			hsv.y *= maskcomponent;
			c.rgb = HSVtoRGB(hsv);
		}
		else if(ControlType == 8) //Control Value
		{
			float3 hsv = RGBtoHSV(c.rgb);
			hsv.z *= maskcomponent;
			c.rgb = HSVtoRGB(hsv);
		}
		else if(ControlType == 9) //Control Value
		{
			c.rgb = lerp(c.rgb, Pixelate(Content, linearSampler, input.uv, maskcomponent), maskcomponent);
		}
	}
	
	return c;
}

technique11 MaskPass
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS_Textured() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Textured() ) );
	}
}