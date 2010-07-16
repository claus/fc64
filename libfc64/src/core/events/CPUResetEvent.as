package core.events
{
	import flash.events.Event;

	public class CPUResetEvent extends Event
	{
		public var pcOld:uint;
		public var pcNew:uint;
		
		/**
		* Defines the value of the type property of a CPUResetEvent object.
		*/		
		public static const CPU_RESET:String = "cpuReset";


		public function CPUResetEvent(type:String, pcOld:uint, pcNew:uint)
		{
			super(type);
			this.pcOld = pcOld;
			this.pcNew = pcNew;
		}


		override public function clone():Event {
			return new CPUResetEvent(type, pcOld, pcNew);
		}

		override public function toString():String {
			return "[CPUResetEvent pcOld:" + pcOld + ", pcNew:" + pcNew + "]";
		}
	}
}
