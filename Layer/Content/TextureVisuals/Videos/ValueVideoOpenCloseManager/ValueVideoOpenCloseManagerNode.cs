#region usings
using System;
using System.ComponentModel.Composition;
using System.Collections.Generic;
using System.Collections.ObjectModel;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
using System.Linq;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "VideoOpenCloseManager", Category = "Value", Help = "Basic template with one value in/out", Tags = "c#")]
	#endregion PluginInfo
	public class ValueVideoOpenCloseManagerNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Input", DefaultValue = 1.0)]
		public IDiffSpread<string> FInput;

		[Output("Open")]
		public ISpread<bool> Open;

		[Output("Close")]
		public ISpread<bool> Close;
		
		[Output("List")]
		public ISpread<string> OutputList;
		
		[Import()]
		public ILogger FLogger;
		#endregion fields & pins

		ObservableCollection<string> myList = new ObservableCollection<string>();
		
		ValueVideoOpenCloseManagerNode()
		{
			myList.CollectionChanged += myList_CollectionChanged;
		}
	
		public void Evaluate(int SpreadMax)
		{
			Open.SliceCount = SpreadMax;
			myList.CollectionChanged += myList_CollectionChanged;
			if(FInput.IsChanged)
			{

			}
		}
		
		
		void myList_CollectionChanged(object sender, System.Collections.Specialized.NotifyCollectionChangedEventArgs e)
		{
        //list changed - an item was added.
        if (e.Action == System.Collections.Specialized.NotifyCollectionChangedAction.Add)
        {
            //Do what ever you want to do when an item is added here...
            //the new items are available in e.NewItems
        }
			
		if (e.Action == System.Collections.Specialized.NotifyCollectionChangedAction.Remove)
        {
            //Do what ever you want to do when an item is added here...
            //the new items are available in e.NewItems
        }
	}
}
}