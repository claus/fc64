/*
 * Copyright notice
 *
 * (c) 2005-2010 Darron Schall, Claus Wahlers.  All rights reserved.
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
	import c64.events.DebuggerEvent;
	import c64.events.FrameRateInfoEvent;
	import c64.memory.MemoryManager;
	import c64.screen.Renderer;
	
	import core.cpu.CPU6502;
	import core.events.CPUResetEvent;
	
	import flash.utils.ByteArray;
	
	import mx.core.ByteArrayAsset;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	[Event( name="cpuReset", type="core.events.CPUResetEvent" )]
	[Event( name="frameRateInfo", type="c64.events.FrameRateInfoEvent" )]
	[Event( name="stop", type="c64.events.DebuggerEvent" )]
	
	/**
	 *
	 */
	public class FC64UIComponent extends UIComponent
	{
		
		private var _cpu:CPU6502;
		
		private var _mem:MemoryManager;
		
		private var _renderer:Renderer;
		
		/**
		 * Constuctor
		 */
		public function FC64UIComponent()
		{
			super();
			
			addEventListener( FlexEvent.INITIALIZE, onInitialize );
			
			// cast embedded roms to bytearrays 
			var romKernel:ByteArray = new ROMEmbeds.KERNEL() as ByteArrayAsset;
			var romBasic:ByteArray = new ROMEmbeds.BASIC() as ByteArrayAsset;
			var romChar:ByteArray = new ROMEmbeds.CHAR() as ByteArrayAsset;
			
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
		
		/**
		 *
		 */
		override protected function createChildren():void
		{
			super.createChildren();
			
			if ( !_renderer )
			{
				// create renderer
				_renderer = new Renderer( _cpu, _mem );
				_renderer.width = 403;
				_renderer.height = 284;
				_renderer.addEventListener( "frameRateInfoInternal", onFrameRateInfo );
				_renderer.addEventListener( "stopInternal", onStop );
				addChild( _renderer );
			}
		}
		
		/**
		 *
		 */
		override protected function measure():void
		{
			measuredWidth = 403;
			measuredMinWidth = 403;
			
			measuredHeight = 284;
			measuredMinHeight = 284;
		}
		
		/**
		 *
		 */
		private function onInitialize( e:FlexEvent ):void
		{
			removeEventListener( FlexEvent.INITIALIZE, onInitialize );
			
			// Initialize and enable keyboard
			_mem.cia1.keyboard.initialize( _cpu, systemManager.stage );
			_mem.cia1.keyboard.enabled = true;
			
			// Start renderer
			_renderer.start();
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

