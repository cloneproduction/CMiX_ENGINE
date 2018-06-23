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

        [Input("Add", IsBang = true)]
        public IDiffSpread<bool> FAdd;

        [Input("Add Key", DefaultString = "")]
        public ISpread<string> FAddKey;

        [Input("Add Value", DefaultString = "")]
        public IDiffSpread<ISpread<string>> FAddValue;


        [Input("Update")]
        public ISpread<bool> FUpdate;

        [Input("Update Key", DefaultString = "")]
        public ISpread<string> FUpdateKey;

        [Input("Update Value", DefaultString = "")]
        public IDiffSpread<ISpread<string>> FUpdateValue;


        [Input("Delete", IsBang = true)]
        public IDiffSpread<bool> FDelete;

        [Input("Delete Key")]
        public IDiffSpread<string> FDeleteKey;


        [Input("Output Key" )]
        public IDiffSpread<string> FQueryKey;


        [Output("Output")]
		public ISpread<ISpread<string>> FOutputQueryValue;

        #endregion fields & pins
        Dictionary<string, ISpread<string>> dict = new Dictionary<string, ISpread<string>>();


        public void Evaluate(int SpreadMax)
		{
            if (FAdd.IsChanged)
            {
                if(FAddValue.SliceCount != 0 && FAddKey.SliceCount != 0)
                {
                    for (int i = 0; i < FAddKey.SliceCount; i++)
                    {
                        if (!FAdd[i]) continue;
                        if (dict.ContainsKey(FAddKey[i]) == false)
                        {
                            dict.Add(FAddKey[i], FAddValue[i].Clone());
                        }
                    }
                }
            }

            if (FUpdate.IsChanged)
            {
                if (FUpdateKey.SliceCount != 0 && FUpdateValue.SliceCount != 0)
                {
                    for (int i = 0; i < FUpdateKey.SliceCount; i++)
                    {
                        if (FUpdate[i])
                        {
                            if (dict.ContainsKey(FUpdateKey[i]))
                            {
                                dict[FUpdateKey[i]] = FUpdateValue[i].Clone();
                            }
                        }
                    }
                }
            }

            if (FDelete.IsChanged && FDeleteKey.SliceCount != 0)
            {
                for (int i = 0; i < FDeleteKey.SliceCount; i++)
                {
                    if (dict.ContainsKey(FDeleteKey[i]) == true)
                    {
                        dict.Remove(FDeleteKey[i]);
                    }
                }
            }

            FOutputQueryValue.SliceCount = FQueryKey.SliceCount;

            for (int i = 0; i < FQueryKey.SliceCount; i++)
            {
                if (FQueryKey.IsChanged || FDeleteKey.IsChanged || FUpdate.IsChanged || FAdd.IsChanged || FDelete.IsChanged)
                {
                    if (FQueryKey[i] == null)
                    {
                        FOutputQueryValue[i].SliceCount = 0;
                        continue;
                    }

                    if (!dict.ContainsKey(FQueryKey[i]))
                    {
                        FOutputQueryValue[i].SliceCount = 0;
                        continue;
                    }

                    if (dict.ContainsKey(FQueryKey[i]))
                    {
                        FOutputQueryValue[i] = dict[FQueryKey[i]];
                    }
                }
            }
        }
	}
}