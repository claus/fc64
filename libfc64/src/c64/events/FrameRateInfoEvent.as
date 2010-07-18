package c64.events
{
	import flash.events.Event;
	
	public class FrameRateInfoEvent extends Event
	{
		public var fps:Number;
		
		public var frameTime:Number;
		
		/**
		 * Defines the value of the type property of a FrameRateInfoEvent object.
		 */
		public static const FRAME_RATE_INFO:String = "frameRateInfo";
		
		
		public function FrameRateInfoEvent( type:String, frameTime:Number )
		{
			super( type );
			this.fps = Math.round( 10000 / frameTime ) / 10;
			this.frameTime = frameTime;
		}
		
		
		override public function clone():Event
		{
			return new FrameRateInfoEvent( type, frameTime );
		}
		
		override public function toString():String
		{
			return "[FrameRateInfoEvent frameTime:" + frameTime + ", fps:" + fps + "]";
		}
	}
}


