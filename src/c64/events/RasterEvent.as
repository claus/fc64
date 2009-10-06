package c64.events
{
	import flash.events.Event;

	public class RasterEvent extends Event
	{
		public var raster:uint;
		
		/**
		* Defines the value of the type property of a RasterEvent object.
		*/		
		public static const RASTER:String = "raster";


		public function RasterEvent(type:String, raster:uint)
		{
			super(type);
			this.raster = raster;
		}

		override public function clone():Event {
			return new RasterEvent(type, raster);
		}

		override public function toString():String {
			return "[RasterEvent raster:" + raster + "]";
		}
	}
}