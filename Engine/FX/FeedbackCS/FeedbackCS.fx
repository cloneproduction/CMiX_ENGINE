SamplerState s0 <bool visible=false;string uiname="Sampler";> {Filter=MIN_MAG_MIP_LINEAR;AddressU=CLAMP;AddressV=CLAMP;};

Texture2DArray texarray;
int texcount;
int2 Reso=512;

RWStructuredBuffer<float4> Output : BACKBUFFER;
StructuredBuffer<int>offsetID;
StructuredBuffer<uint>Enable;
StructuredBuffer<float>Fade;

[numthreads(64, 1, 1)]
void CSFeedback( uint3 DTid : SV_DispatchThreadID )
{
	for(int i = 0; i < texcount; i++){
		float2 uv=(float2(DTid.x%Reso.x,DTid.x/Reso.x)+0.5)/Reso;

		if(Enable[i] == 0)
		{
			Output[DTid.x+offsetID[i]]=float4(texarray.SampleLevel(s0,float3(uv, i),0));
		}
		else
		{
			float4 c=Output[DTid.x+offsetID[i]];
			float4 cc = texarray.SampleLevel(s0,float3(uv, i),0);
			Output[DTid.x+offsetID[i]]= lerp(lerp(cc,c,Fade[i]), cc, cc.a);	
		}
	}
}

technique11 Feedback
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_4_0, CSFeedback() ) );
	}
}