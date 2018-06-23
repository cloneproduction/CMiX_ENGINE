#region usings
using System;
using System.ComponentModel.Composition;
using System.Timers;
using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "DateTime", Category = "Value", Help = "Basic template with one value in/out", Tags = "c#")]
	#endregion PluginInfo
	
	public class ValueDateTimeNode : IPluginEvaluate
	{
		#region fields & pins

		[Output("Output")]
		public ISpread<double> FDateTime;

		[Import()]
		public ILogger FLogger;
		#endregion fields & pins

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			FDateTime.SliceCount = SpreadMax;
			double ms = (DateTime.Now - DateTime.MinValue).TotalMilliseconds;
			FDateTime[0] = ms;

			//FLogger.Log(LogType.Debug, "hi tty!");
		}
	}
}
