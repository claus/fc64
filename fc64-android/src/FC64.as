package
{
	import c64.events.DebuggerEvent;
	import c64.events.FrameRateInfoEvent;
	import c64.memory.MemoryManager;
	import c64.screen.Renderer;
	
	import core.cpu.CPU6502;
	import core.events.CPUResetEvent;
	import core.events.OSInitializedEvent;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageOrientation;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.StageOrientationEvent;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	
	import mx.core.ByteArrayAsset;
	
	/**
	 *
	 */
	public class FC64 extends Sprite
	{
		[Embed( source="/assets/kernal.901227-03.bin", mimeType="application/octet-stream" )]
		private const ROMKernel:Class;
		
		[Embed( source="/assets/basic.901226-01.bin", mimeType="application/octet-stream" )]
		private const ROMBasic:Class;
		
		[Embed( source="/assets/characters.901225-01.bin", mimeType="application/octet-stream" )]
		private const ROMChar:Class;
		
		private var cpu:CPU6502;
		
		private var mem:MemoryManager;
		
		private var renderer:Renderer;
		
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
			
			// cast embedded roms to bytearrays
			var romKernel:ByteArray = new ROMKernel() as ByteArrayAsset;
			var romBasic:ByteArray = new ROMBasic() as ByteArrayAsset;
			var romChar:ByteArray = new ROMChar() as ByteArrayAsset;
			
			// create and initialize memory manager
			mem = new MemoryManager();
			mem.setMemoryBank( MemoryManager.MEMBANK_KERNAL, 0xe000, romKernel.length, romKernel );
			mem.setMemoryBank( MemoryManager.MEMBANK_BASIC, 0xa000, romBasic.length, romBasic );
			mem.setMemoryBank( MemoryManager.MEMBANK_CHARACTER, 0xd000, romChar.length, romChar );
			
			// create cpu
			cpu = new CPU6502( mem );
			// $A483 is the main Basic program loop
			// set a breakpoint here so we know when the C64 is ready for action
			cpu.addEventListener( "cpuResetInternal", onCPUReset );
			cpu.setBreakpoint( 0xA483, 255 );
			
			// create renderer
			renderer = new Renderer( cpu, mem );
			renderer.x = 0;
			renderer.y = 0;
			renderer.width = 403;
			renderer.height = 284;
			renderer.addEventListener( "frameRateInfoInternal", onFrameRateInfo );
			renderer.addEventListener( "stopInternal", onStop );
			addChild( renderer );
			
			// Initialize and enable keyboard
			mem.cia1.keyboard.initialize( cpu, stage );
			mem.cia1.keyboard.enabled = true;
			
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
			renderer.start();
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
			cpu.setBreakpoint( 0xA483, 255 );
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
				
				renderer.start();
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
//				mem.write( addr++, ba[ i ] );
//			}
//			if ( startAddress == 0x0801 )
//			{
//				// run command
//				var charsInBuffer:uint = fc64.mem.read( 0xc6 );
//				if ( charsInBuffer < fc64.mem.read( 0x0289 ) - 4 )
//				{
//					var keyboardBuffer:uint = 0x0277 + charsInBuffer + 1;
//					mem.write( keyboardBuffer++, 82 ); // R
//					mem.write( keyboardBuffer++, 85 ); // U
//					mem.write( keyboardBuffer++, 78 ); // N
//					mem.write( keyboardBuffer++, 13 ); // Return
//					mem.write( 0xc6, charsInBuffer + 5 );
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

