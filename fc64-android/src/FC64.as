package
{
	import c64.events.DebuggerEvent;
	import c64.events.FrameRateInfoEvent;
	
	import components.FC64Sprite;
	
	import core.events.CPUResetEvent;
	
	import flash.desktop.NativeApplication;
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageOrientation;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.events.KeyboardEvent;
	import flash.events.StageOrientationEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
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
		private var isPortrait:Boolean = true;
		
		/**
		 * Constructor
		 */
		//[SWF( width="480", height="800", frameRate="60" )]
		public function FC64()
		{
			super();
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			addEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
			
//			NativeApplication.nativeApplication.addEventListener( InvokeEvent.INVOKE, onInvoke );
//			NativeApplication.nativeApplication.addEventListener( Event.ACTIVATE, onActivate );
			NativeApplication.nativeApplication.addEventListener( Event.DEACTIVATE, onDeactivate );
			
//			NativeApplication.nativeApplication.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDown );
			
			init();
		
			//stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
		}
		
		/**
		 *
		 */
		private function init():void
		{
			// Pass the native application through as the keyboard listener
			fc64 = new FC64Sprite( NativeApplication.nativeApplication );
			fc64.addEventListener( CPUResetEvent.CPU_RESET, onCPUReset );
			fc64.addEventListener( FrameRateInfoEvent.FRAMERATE_INFO, onFrameRateInfo );
			fc64.addEventListener( DebuggerEvent.STOP, onStop );
			addChild( fc64 );
			
			// Create text field for fps display
			fpsDisplay = new TextField();
			addChild( fpsDisplay );
			
			// Start up in portrait mode initially
			alignPortrait();
			
			// Listen for orientation changes
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener( StageOrientationEvent.ORIENTATION_CHANGE, onOrientationChange );
			stage.addEventListener( Event.RESIZE, onResizeChange );
			//stage.focus = fc64.renderer;
			
			// Start renderer
			fc64.renderer.start();
		}
		
		/**
		 *
		 */
		private function onInvoke( event:InvokeEvent ):void
		{
//			init()
		}
		
		/**
		 *
		 */
		private function onAddedToStage( event:Event ):void
		{
			fc64.mem.cia1.keyboard.enabled = true;
		}
		
		/**
		 *
		 */
		private function onRemovedFromStage( event:Event ):void
		{
			fc64.mem.cia1.keyboard.enabled = false;
		}
		
		/**
		 *
		 */
		private function onActivate( event:Event ):void
		{
//			fc64.renderer.start();
//			fc64.mem.cia1.keyboard.enabled = true;
		}
		
		/**
		 *
		 */
		private function onDeactivate( event:Event ):void
		{
//			fc64.renderer.stop();
			
			NativeApplication.nativeApplication.exit();
		
//			fc64.mem.cia1.keyboard.enabled = false;
		}
		
		/**
		 *
		 */
		private function onOrientationChange( event:StageOrientationEvent ):void
		{
			alignToOrientation( event.afterOrientation );
		}
		
		/**
		 *
		 */
		private function alignToOrientation( orientation:String ):void
		{
			// Landscape
			if ( orientation == StageOrientation.ROTATED_LEFT
				|| orientation == StageOrientation.ROTATED_RIGHT )
			{
				isPortrait = false;
			}
			else // Portrait
			{
				isPortrait = true;
			}
		}
		
		/**
		 * 
		 */
		private function onResizeChange( event:Event ):void
		{
			if ( isPortrait )
			{
				alignPortrait();
			}
			else
			{
				alignLandscape();
			}
		}
		
		/**
		 *
		 */
		private function alignLandscape():void
		{
			var screenBounds:Rectangle = Screen.mainScreen.bounds;
			//var deviceWidth:int = screenBounds.width;
			var deviceHeight:int = screenBounds.height;
			
			// Scale FC64 to match the height
			fc64.scaleX = fc64.scaleY = 1;
			var newScale:Number = deviceHeight / fc64.height;
			fc64.scaleX = fc64.scaleY = newScale;
			
			// Move the fps text to the right of the renderer
			fpsDisplay.x = fc64.x + fc64.width;
			fpsDisplay.y = 0;
			fpsDisplay.width = 60;
			fpsDisplay.height = deviceHeight;
		}
		
		/**
		 *
		 */
		private function alignPortrait():void
		{
			var screenBounds:Rectangle = Screen.mainScreen.bounds;
			var deviceWidth:int = screenBounds.width;
			//var deviceHeight:int = screenBounds.height;
			
			// Scale FC64 to match the width
			fc64.scaleX = fc64.scaleY = 1;
			var newScale:Number = deviceWidth / fc64.width;
			fc64.scaleX = fc64.scaleY = newScale;
			
			// Move the fps text under the renderer
			fpsDisplay.x = 0;
			fpsDisplay.y = fc64.y + fc64.height;
			fpsDisplay.width = deviceWidth;
			fpsDisplay.height = 60;
		}
		
		/**
		 *
		 */
		private function onKeyDown( event:KeyboardEvent ):void
		{
			if ( event.keyCode == Keyboard.BACK )
			{
				// If we want to handle the Back button differently, we can
				// prevent the event and put our own logic here
				//e.preventDefault();
			}
			else if ( event.keyCode == Keyboard.MENU )
			{
				// FIXME: Open menu with "reset" and rom selections
			}
		}
		
		/**
		 *
		 */
		private function onCPUReset( event:CPUResetEvent ):void
		{
			fc64.cpu.setBreakpoint( 0xA483, 255 );
		}
		
		/**
		 *
		 */
		private function onFrameRateInfo( event:FrameRateInfoEvent ):void
		{
			if ( isPortrait )
			{
				fpsDisplay.text = event.frameTime + " ms/frame " + event.fps + " fps";
			}
			else
			{
				fpsDisplay.text = event.frameTime + " ms\n  /frame\n\n" + event.fps + " fps";
			}
		}
		
		/**
		 *
		 */
		private function onStop( event:DebuggerEvent ):void
		{
			if ( event.breakpointType == 255 )
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
		private function onLoadPRG( event:Event ):void
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

