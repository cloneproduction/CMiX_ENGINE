using System.Windows;
using System.ComponentModel.Composition;
using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;
using VVVV.Core.Logging;


namespace VVVV.Nodes
{
	[PluginInfo(Name = "HexToColor", Category = "Color", Tags = "c#")]
	public class ColorHexToColorNode : IPluginEvaluate
	{
		[Input("Input")]
		public ISpread<string> FInput;
		

		[Output("Output")]
		public ISpread<string> FOutput;

		public void Evaluate(int SpreadMax)
		{
			FOutput.SliceCount = SpreadMax;

			for (int i = 0; i < SpreadMax; i++){
				string hex = FInput[i];
			if (hex.Length > 7){
				hex = hex.Remove(1,2);
			}
				FOutput[i] = hex;
			}
		}
	}
}
