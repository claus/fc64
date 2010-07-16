package c64.events
{
	import flash.events.Event;

	public class DebuggerEvent extends Event
	{
		public var breakpointType:uint;
		
		/**
		* Defines the value of the type property of a DebuggerEvent object.
		*/		
		public static const STOP:String = "stop";


		public function DebuggerEvent(type:String, breakpointType:uint = 0)
		{
			super(type);
			this.breakpointType = breakpointType;
		}


		override public function clone():Event {
			return new DebuggerEvent(type, breakpointType);
		}

		override public function toString():String {
			return "[DebuggerEvent breakpointType:" + breakpointType + "]";
		}
	}
}
