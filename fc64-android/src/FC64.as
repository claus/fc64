package
{
	import c64.events.DebuggerEvent;
	import c64.events.FrameRateInfoEvent;
	
	import components.FC64Sprite;
	
	import core.events.CPUResetEvent;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageOrientation;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.StageOrientationEvent;
	import flash.text.TextField;
	
	/**
	 *
	 */
	public class FC64 extends Sprite
	{
		private var fc64:FC64Sprite;
		
		private var fpsDisplay:TextField;
		
		/**
		 *
		 */
		private var isPortrait:Boolean;
		
		/**
		 * Constructor
		 */
		[SWF( width="464", height="284", frameRate="60" )]
		public function FC64()
		{
			super();
			
			fc64 = new FC64Sprite();
			fc64.addEventListener( CPUResetEvent.CPU_RESET, onCPUReset );
			fc64.addEventListener( FrameRateInfoEvent.FRAMERATE_INFO, onFrameRateInfo );
			fc64.addEventListener( DebuggerEvent.STOP, onStop );
			addChild( fc64 );
			
			// Create text field for fps display
			fpsDisplay = new TextField();
			addChild( fpsDisplay );
			
			// Align UI in the initial landscape mode
			alignLandscape();
			
			// Listen for orientation changes
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener( StageOrientationEvent.ORIENTATION_CHANGE, onOrientationChange );
			
			// Start renderer
			fc64.renderer.start();
		}
		
		/**
		 *
		 */
		private function alignLandscape():void
		{
			// Move the fps text to the right of the renderer
			fpsDisplay.x = 404;
			fpsDisplay.y = 0;
			fpsDisplay.width = 60;
			fpsDisplay.height = 284;
			
			isPortrait = false;
		}
		
		/**
		 *
		 */
		private function alignPortrait():void
		{
			// Move the fps text under the renderer
			fpsDisplay.x = 0;
			fpsDisplay.y = 285;
			fpsDisplay.width = 403;
			fpsDisplay.height = 60;
			
			isPortrait = true;
		}
		
		/**
		 *
		 */
		private function onOrientationChange( e:StageOrientationEvent ):void
		{
			// Landscape
			if ( e.afterOrientation == StageOrientation.ROTATED_LEFT
				|| e.afterOrientation == StageOrientation.ROTATED_RIGHT )
			{
				alignLandscape();
			}
			else // Portrait
			{
				alignPortrait();
			}
		}
		
		/**
		 *
		 */
		private function onCPUReset( e:CPUResetEvent ):void
		{
			fc64.cpu.setBreakpoint( 0xA483, 255 );
		}
		
		/**
		 *
		 */
		private function onFrameRateInfo( e:FrameRateInfoEvent ):void
		{
			if ( isPortrait )
			{
				fpsDisplay.text = e.frameTime + " ms/frame " + e.fps + " fps";
			}
			else
			{
				fpsDisplay.text = e.frameTime + " ms\n  /frame\n\n" + e.fps + " fps";
			}
		}
		
		/**
		 *
		 */
		private function onStop( e:DebuggerEvent ):void
		{
			if ( e.breakpointType == 255 )
			{
//				if ( state == "loading" )
//				{
//					var fileName:String = software.selectedItem.filename;
//					var request:URLRequest = new URLRequest( fileName );
//					var loader:URLLoader = new URLLoader();
//					loader.dataFormat = URLLoaderDataFormat.BINARY;
//					loader.addEventListener( Event.COMPLETE, onLoadPRG );
//					loader.load( request );
//				}
//				else
//				{
//					software.enabled = true;
//				}
				
				fc64.renderer.start();
			}
		}
		
		/**
		 *
		 */
		private function onLoadPRG( e:Event ):void
		{
//			var ba:ByteArray = ByteArray( e.target.data );
//			// get start address
//			ba.endian = Endian.LITTLE_ENDIAN;
//			var startAddress:int = ba.readShort();
//			// copy contents
//			var addr:int = startAddress;
//			for ( var i:uint = 0x02; i < ba.length; i++ )
//			{
//				fc64.mem.write( addr++, ba[ i ] );
//			}
//			if ( startAddress == 0x0801 )
//			{
//				// run command
//				var charsInBuffer:uint = fc64.mem.read( 0xc6 );
//				if ( charsInBuffer < fc64.mem.read( 0x0289 ) - 4 )
//				{
//					var keyboardBuffer:uint = 0x0277 + charsInBuffer + 1;
//					fc64.mem.write( keyboardBuffer++, 82 ); // R
//					fc64.mem.write( keyboardBuffer++, 85 ); // U
//					fc64.mem.write( keyboardBuffer++, 78 ); // N
//					fc64.mem.write( keyboardBuffer++, 13 ); // Return
//					fc64.mem.write( 0xc6, charsInBuffer + 5 );
//				}
//			}
//			else
//			{
//				fc64.cpu.pc = startAddress;
//			}
//			software.enabled = true;
//			software.selectedIndex = -1;
//			loadButton.enabled = false;
//			state = "normal";
		}
	
//		private function onOSInitialized( event:OSInitializedEvent ):void
//		{
//		}
	}
}

