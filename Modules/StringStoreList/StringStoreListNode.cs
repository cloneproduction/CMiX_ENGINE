#region usings
using System;
using System.ComponentModel.Composition;
using System.Collections.Generic;
using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "StoreList", AutoEvaluate=true, Category = "String", Help = "Basic template with one string in/out", Tags = "c#")]
	#endregion PluginInfo
	
	public class StringStoreListNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("SelectedTexFilename", DefaultString = "")]
		public IDiffSpread<string> FSelectedTexFilename;
		
		[Input("SelectedTexBinsize")]
		public ISpread<int> FSelectedTexBinSize;
		
		[Input("DefaultChannelCount")]
		public ISpread<int> FDefaultChannelCount;
		
		[Input("OnReceive")]
		public IDiffSpread<bool> FOnReceive;
		
		[Output("Output")]
		public ISpread<ISpread<string>> FOutput;

		[Import()]
		public ILogger FLogger;
		#endregion fields & pins

		//called when data for any output pin is requested
		List<List<string>> SelectedTexture = new List<List<string>>();
		bool init = true;
		
		public void Evaluate(int SpreadMax)
		{
			FOutput.SliceCount = FOnReceive.SliceCount;
	
			if(init == true)
			{
				for(int i = 0; i < FDefaultChannelCount[0]; i++)
				{
					SelectedTexture.Add(new List<string>());
					FOutput[i].AssignFrom(SelectedTexture[i]);
				}
				init = false;

			}
	
			for (int i = 0; i < FOnReceive.SliceCount; i++)
			{
				if(FOnReceive[i] == true)
				{
					SelectedTexture[i].Clear();
					for(int j = 0; j < FSelectedTexBinSize[i]; j++)
					{
						SelectedTexture[i].Add(FSelectedTexFilename[j]);
					}
				FOutput[i].AssignFrom(SelectedTexture[i]);
				}
			}
		}
	}
}