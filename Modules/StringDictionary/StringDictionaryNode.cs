#region usings
using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Core.Logging;
using System.Collections.Generic;

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
            if (FKey.IsChanged)
            {
                if (FKey.SliceCount > 0 && FValue.SliceCount > 0)
                {
                    for (int i = 0; i < FKey.SliceCount; i++)
                    {
                        if (!dict.ContainsKey(FKey[i]) )
                        {
                            dict.Add(FKey[i], FValue[i].Clone());
                            FOutputQueryValue.SliceCount = dict.Count;
                            FOutputQueryValue[i] = dict[FKey[i]];
                        }
                    }
                }
            }

            if (FUpdate.IsChanged)
            {
                if (FUpdate.SliceCount > 0 && FValue.SliceCount > 0)
                {
                    for (int i = 0; i < FUpdate.SliceCount; i++)
                    {
                        if (FUpdate[i])
                        {
                            dict[FKey[i]] = FValue[i].Clone();
                            FOutputQueryValue.SliceCount = dict.Count;
                            FOutputQueryValue[i] = dict[FKey[i]];
                        }
                    }
                }
            }

            if (FDeleteKey.IsChanged)
            {
                if(FDeleteKey.SliceCount > 0)
                {
                    for (int i = FDeleteKey.SliceCount - 1; i >= 0; i--)
                    {
                        if (dict.ContainsKey(FDeleteKey[i]))
                        {
                            dict.Remove(FDeleteKey[i]);
                            FOutputQueryValue.SliceCount = dict.Count;
                        }
                    }

                    for (int i = 0; i < dict.Count; i++)
                    {
                        FOutputQueryValue[i] = dict[FKey[i]];
                    }
                }
            }
        }
	}
}