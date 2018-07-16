#region usings
using System;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
using System.Collections.Generic;
using System.Windows.Forms;
#endregion usings

namespace VVVV.Nodes
{
	[PluginInfo(Name = "Dictionary", Category = "String", Help = "Dico", Tags = "c#", AutoEvaluate = true)]

	public class StringDictionaryNode : IPluginEvaluate
	{
        #region fields & pins

        [Input("Value", DefaultString = "")]
        public IDiffSpread<ISpread<string>> FValue;

        [Input("Update")]
        public IDiffSpread<bool> FUpdate;

        [Input("Key")]
        public IDiffSpread<string> FKey;

        [Input("Delete Key")]
        public IDiffSpread<string> FDeleteKey;

        [Output("Output")]
		public ISpread<ISpread<string>> FOutputQueryValue;

        #endregion fields & pins

        Dictionary<string, ISpread<string>> dict = new Dictionary<string, ISpread<string>>();

        public void Evaluate(int SpreadMax)
		{
            FOutputQueryValue.SliceCount = FKey.SliceCount;

            if (FKey.IsChanged)
            {
                if (FKey.SliceCount != 0)
                {
                    for (int i = 0; i < FKey.SliceCount; i++)
                    {
                        if (!dict.ContainsKey(FKey[i]))
                        {
                            dict.Add(FKey[i], FValue[i].Clone());
                        }
                        FOutputQueryValue[i] = dict[FKey[i]];
                    }
                }
            }

            if (FDeleteKey.IsChanged)
            {
                if(FDeleteKey.SliceCount != 0)
                {
                    for (int i = 0; i < FDeleteKey.SliceCount; i++)
                    {
                        if (dict.ContainsKey(FDeleteKey[i]) == true)
                        {
                            dict.Remove(FDeleteKey[i]);
                        }
                        if (FDeleteKey.SliceCount > 0)
                            FOutputQueryValue[i] = dict[FKey[i]];
                    }
                }
            }

            for (int i = 0; i < FUpdate.SliceCount; i++)
            {
                if (FUpdate.SliceCount != 0)
                {
                    if (FUpdate[i])
                    {
                        dict[FKey[i]] = FValue[i].Clone();
                    }
                    FOutputQueryValue[i] = dict[FKey[i]];
                }
            }
        }
	}
}