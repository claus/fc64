/*
 * Copyright notice
 *
 * (c) 2005-2006 Darron Schall, Claus Wahlers.  All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

package components
{
	import mx.core.UIComponent;
	import flash.utils.ByteArray;
	import flash.events.*;
	import core.events.*;
	import core.cpu.*;
	import c64.memory.*;
	import c64.screen.*;
	import c64.events.*;
	import flash.display.DisplayObject;
	
	[Event( name="cpuReset", type="core.events.CPUResetEvent" )]
	[Event( name="frameRateInfo", type="c64.events.FrameRateInfoEvent" )]
	[Event( name="stop", type="c64.events.DebuggerEvent" )]
	
	public class FC64 extends UIComponent
	{
		
		[Embed( source="/assets/kernal.901227-03.bin", mimeType="application/octet-stream" )]
		private const ROMKernel:Class;
		
		[Embed( source="/assets/basic.901226-01.bin", mimeType="application/octet-stream" )]
		private const ROMBasic:Class;
		
		[Embed( source="/assets/characters.901225-01.bin", mimeType="application/octet-stream" )]
		private const ROMChar:Class;
		
		public var listenerTarget:DisplayObject;
		
		private var _cpu:CPU6502;
		
		private var _mem:MemoryManager;
		
		private var _renderer:Renderer;
		
		
		public function FC64()
		{
			super();
			
			addEventListener( "initialize", onInitialize );
			
			// cast embedded roms to bytearrays
			var romKernel:ByteArray = new ROMKernel() as ByteArray;
			var romBasic:ByteArray = new ROMBasic() as ByteArray;
			var romChar:ByteArray = new ROMChar() as ByteArray;
			
			// create and initialize memory manager
			_mem = new MemoryManager();
			_mem.setMemoryBank( MemoryManager.MEMBANK_KERNAL, 0xe000, romKernel.length, romKernel );
			_mem.setMemoryBank( MemoryManager.MEMBANK_BASIC, 0xa000, romBasic.length, romBasic );
			_mem.setMemoryBank( MemoryManager.MEMBANK_CHARACTER, 0xd000, romChar.length, romChar );
			
			// create cpu
			_cpu = new CPU6502( _mem );
			
			// $A483 is the main Basic program loop
			// set a breakpoint here so we know when the C64 is ready for action
			_cpu.addEventListener( "cpuResetInternal", onCPUReset );
			_cpu.setBreakpoint( 0xA483, 255 );
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			if ( !_renderer )
			{
				// create renderer
				_renderer = new Renderer( _cpu, _mem );
				_renderer.addEventListener( "frameRateInfoInternal", onFrameRateInfo );
				_renderer.addEventListener( "stopInternal", onStop );
				addChild( _renderer );
			}
		}
		
		override protected function measure():void
		{
			super.measure();
			measuredWidth = 403;
			measuredMinWidth = 403;
			measuredHeight = 284;
			measuredMinHeight = 284;
		}
		
		private function onInitialize( eventObj:Event ):void
		{
			// Initialize and enable keyboard
			_mem.cia1.keyboard.initialize( _cpu, systemManager.stage );
			_mem.cia1.keyboard.enabled = true;
			// Start renderer
			_renderer.start();
		}
		
		private function onCPUReset( e:CPUResetEvent ):void
		{
			dispatchEvent( new CPUResetEvent( "cpuReset", e.pcOld, e.pcNew ) );
		}
		
		private function onFrameRateInfo( e:FrameRateInfoEvent ):void
		{
			dispatchEvent( new FrameRateInfoEvent( "frameRateInfo", e.frameTime ) );
		}
		
		private function onStop( e:DebuggerEvent ):void
		{
			dispatchEvent( new DebuggerEvent( "stop", e.breakpointType ) );
		}
		
		
		public function get cpu():CPU6502
		{
			return _cpu;
		}
		
		public function get mem():MemoryManager
		{
			return _mem;
		}
		
		public function get renderer():Renderer
		{
			return _renderer;
		}
	}
}
