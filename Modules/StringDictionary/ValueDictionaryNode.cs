#region usings
using System;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
using System.Collections.Generic;
#endregion usings

namespace VVVV.Nodes
{
    [PluginInfo(Name = "Dictionary", Category = "Value", Help = "Dico", Tags = "c#")]

    public class ValueDictionaryNode : IPluginEvaluate
    {
        #region fields & pins

        [Input("Add", IsBang = true)]
        public IDiffSpread<bool> FAdd;

        [Input("Add Key", DefaultString = "")]
        public ISpread<string> FAddKey;

        [Input("Add Value", DefaultString = "")]
        public IDiffSpread<double> FAddValue;


        [Input("Update", IsBang = true)]
        public IDiffSpread<bool> FUpdate;

        [Input("Update Key", DefaultString = "")]
        public ISpread<string> FUpdateKey;

        [Input("Update Value", DefaultString = "")]
        public IDiffSpread<double> FUpdateValue;


        [Input("Delete", IsBang = true)]
        public IDiffSpread<bool> FDelete;

        [Input("Delete Key")]
        public IDiffSpread<string> FDeleteKey;


        [Input("Output Key")]
        public IDiffSpread<string> FQueryKey;


        [Output("Output")]
        public ISpread<double> FOutputQueryValue;

        #endregion fields & pins

        Dictionary<string, double> dict = new Dictionary<string, double>();

        public void Evaluate(int SpreadMax)
        {


            if (FAdd[0] == true && FAddValue.SliceCount != 0 && FAddKey.SliceCount != 0)
            {
                for (int i = 0; i < FAddValue.SliceCount; i++)
                {
                    if (!dict.ContainsKey(FAddKey[i]))
                    {
                        dict[FAddKey[i]] = FAddValue[i];
                    }
                }
            }


            if (FUpdate.IsChanged)
            {
                for (int i = 0; i < FUpdateValue.SliceCount; i++)
                {
                    if (!FUpdate[i]) continue;

                    if (FUpdate[i] == true)
                    {
                        if (dict.ContainsKey(FUpdateKey[i]))
                        {
                            dict[FUpdateKey[i]] = FUpdateValue[i];
                        }
                    }
                }
            }

            if (FDelete.IsChanged)
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
                        //FOutputQueryValue[i].SliceCount = 0;
                        continue;
                    }

                    if (dict.ContainsKey(FQueryKey[i]) == false)
                    {
                        //FOutputQueryValue[i].SliceCount = 0;
                        continue;
                    }

                    if (dict.ContainsKey(FQueryKey[i]) == true)
                    {
                        FOutputQueryValue[i] = dict[FQueryKey[i]];
                    }
                }
            }
        }
    }
}