package components 
{
	import c64.events.DebuggerEvent;
	import c64.events.FrameRateInfoEvent;
	import c64.memory.MemoryManager;
	import c64.screen.Renderer;
	
	import core.cpu.CPU6502;
	import core.events.CPUResetEvent;
	
	import flash.display.Sprite;
	import flash.utils.ByteArray;
	
	import mx.core.ByteArrayAsset;
	
	/**
	 *
	 */
	public class FC64Sprite extends Sprite
	{
		private var _cpu:CPU6502;
		
		private var _mem:MemoryManager;
		
		private var _renderer:Renderer;
		
		/**
		 * Constructor
		 */
		public function FC64Sprite()
		{
			super();
			
			// cast embedded roms to bytearrays 
			var romKernel:ByteArray = new ROMEmbeds.KERNEL() as ByteArrayAsset;
			var romBasic:ByteArray = new ROMEmbeds.BASIC() as ByteArrayAsset;
			var romChar:ByteArray = new ROMEmbeds.CHAR() as ByteArrayAsset;
			
			// create and initialize Memory manager
			_mem = new MemoryManager();
			_mem.setMemoryBank( MemoryManager.MEMBANK_KERNAL, 0xe000, romKernel.length, romKernel );
			_mem.setMemoryBank( MemoryManager.MEMBANK_BASIC, 0xa000, romBasic.length, romBasic );
			_mem.setMemoryBank( MemoryManager.MEMBANK_CHARACTER, 0xd000, romChar.length, romChar );
			
			// create _cpu
			_cpu = new CPU6502( _mem );
			// $A483 is the main Basic program loop
			// set a breakpoint here so we know when the C64 is ready for action
			_cpu.addEventListener( "_cpuResetInternal", onCPUReset );
			_cpu.setBreakpoint( 0xA483, 255 );
			
			// create _renderer
			_renderer = new Renderer( _cpu, _mem );
			_renderer.x = 0;
			_renderer.y = 0;
			_renderer.width = 403;
			_renderer.height = 284;
			_renderer.addEventListener( "frameRateInfoInternal", onFrameRateInfo );
			_renderer.addEventListener( "stopInternal", onStop );
			addChild( _renderer );
			
			// Initialize and enable keyboard
			_mem.cia1.keyboard.initialize( _cpu, stage );
			_mem.cia1.keyboard.enabled = true;
		}
		
		/**
		 *
		 */
		protected function onCPUReset( e:CPUResetEvent ):void
		{
			dispatchEvent( new CPUResetEvent( CPUResetEvent.CPU_RESET, e.pcOld, e.pcNew ) );
		}
		
		/**
		 *
		 */
		protected function onFrameRateInfo( e:FrameRateInfoEvent ):void
		{
			dispatchEvent( new FrameRateInfoEvent( FrameRateInfoEvent.FRAMERATE_INFO, e.frameTime ) );
		}
		
		/**
		 *
		 */
		protected function onStop( e:DebuggerEvent ):void
		{
			dispatchEvent( new DebuggerEvent( DebuggerEvent.STOP, e.breakpointType ) );
		}
		
		/**
		 *
		 */
		public function get cpu():CPU6502
		{
			return _cpu;
		}
		
		/**
		 *
		 */
		public function get mem():MemoryManager
		{
			return _mem;
		}
		
		/**
		 *
		 */
		public function get renderer():Renderer
		{
			return _renderer;
		}
	}
}

