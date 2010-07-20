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
 */

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
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import mx.core.ByteArrayAsset;
	
	/**
	 *
	 */
	public class FC64 extends Sprite
	{
		private var fc64:FC64Sprite;
		
		/**
		 * The amount of time (in ms) to wait before we similate a press and
		 * release of a key so that it registers in the FC64 cpu.
		 */
		private static const FC64_CPU_KEY_REGISTER_DELAY:int = 200;
		
		/**
		 * The timing threshold that we use to determine if a keyDown/keyUp event
		 * handling sequence is coming from the keyboard (when the time between
		 * event handlers is less than this delay) or the trackball (when the
		 * time between is greater than the delay).
		 */
		private static const VIRTUAL_KEY_DELAY_THRESHOLD:int = 10;
		
		
		// FIXME: Remove this and let the user select roms from SD card
		[Embed( source="/assets/roms/COLOURGALAGA.PRG", mimeType="application/octet-stream" )]
		public static const GALAGA_COLOR:Class;
		
		private var romLoaded:Boolean = false;
		
		/**
		 *
		 */
		// TODO: We can probably replace with a getter that checks
		// stage.deviceOrientation against StageOrientation constants
		private var isPortrait:Boolean = true;
		
		/**
		 * Constructor
		 */
		[SWF( width="480", height="800", frameRate="60" )]
		public function FC64()
		{
			super();
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			addEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
			
//			NativeApplication.nativeApplication.addEventListener( InvokeEvent.INVOKE, onInvoke );
//			NativeApplication.nativeApplication.addEventListener( Event.ACTIVATE, onActivate );
			NativeApplication.nativeApplication.addEventListener( Event.DEACTIVATE, onDeactivate );
			
			init();
		}
		
		/**
		 *
		 */
		private function init():void
		{	
			// Pass the native application through as the keyboard listener
			fc64 = new FC64Sprite( NativeApplication.nativeApplication /* fpsDisplay */ );
			fc64.addEventListener( CPUResetEvent.CPU_RESET, onCPUReset );
			fc64.addEventListener( FrameRateInfoEvent.FRAME_RATE_INFO, onFrameRateInfo );
			fc64.addEventListener( DebuggerEvent.STOP, onStop );
			addChild( fc64 );
			
			// Start up in portrait mode initially
			alignPortrait();
			
			// Listen for orientation changes
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener( StageOrientationEvent.ORIENTATION_CHANGE, onOrientationChange );
			stage.addEventListener( Event.RESIZE, onResizeChange );
			
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
			stage.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDown );
			stage.addEventListener( KeyboardEvent.KEY_UP, onKeyUp );
		}
		
		/**
		 *
		 */
		private function onRemovedFromStage( event:Event ):void
		{
			stage.removeEventListener( KeyboardEvent.KEY_DOWN, onKeyDown );
			stage.removeEventListener( KeyboardEvent.KEY_UP, onKeyUp );
		}
		
		/**
		 *
		 */
		private function onActivate( event:Event ):void
		{
//			fc64.renderer.start();
		}
		
		/**
		 *
		 */
		private function onDeactivate( event:Event ):void
		{
//			fc64.renderer.stop();
			
			// Close the application when sent to the background
			// FIXME: This probably isn't the desired action
			NativeApplication.nativeApplication.exit();
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
		}
		
		protected var keyDownTime:int;
		
		/**
		 *
		 */
		protected function onKeyDown( event:KeyboardEvent ):void
		{
			var keyCode:int = event.keyCode;
			
			if ( keyCode == Keyboard.BACK )
			{
				// If we want to handle the Back button differently, we can
				// prevent the event and put our own logic here
				event.preventDefault();
				
				// FIXME: This is temporary - Load galaga color into memory.  If already
				// loaded then reset the CPU
				if ( romLoaded )
				{
					// Reset the CPU
					fc64.cpu.reset();
					
					romLoaded = false;
				}
				else
				{
					loadProgram( new GALAGA_COLOR() as ByteArrayAsset );
					
					romLoaded = true;
				}
			}
			else if ( keyCode == Keyboard.MENU )
			{
				// FIXME: Open menu with "reset" and rom selections (file browser to load
				// roms from arbitrary locations on SD card?).  
			}
			else
			{
				// Record when the key down happened, since when interacting with the
				// keyboard we get a key down immediately followed by a key up, but
				// when using the track ball we get a key down immediately on track ball 
				// press and a key up on track ball release.  We can calculate the time 
				// between keyDown and keyUp to differentiate pressing ENTER on the vritual
				// keyboard and pressing the trackball.
				keyDownTime = getTimer();
			}
		}
		
		/**
		 *
		 */
		protected function onKeyUp( event:KeyboardEvent ):void
		{
			var keyUpTime:int = getTimer();
			var keyCode:int = event.keyCode;
			
			if ( keyUpTime - keyDownTime < VIRTUAL_KEY_DELAY_THRESHOLD )
			{
				// We received an immedaite press and then release - interacting
				// with the virtual keyboard we so need to release the key
				// in fc64, but we have to do this after enough of a delay so
				// that the fc64 internal cpu picks up the key press.
				fc64.pressKey( keyCode );
				setTimeout( fc64.releaseKey, FC64_CPU_KEY_REGISTER_DELAY, keyCode );
			}
			else if ( keyCode == Keyboard.ENTER )
			{
				// Delay between down and up, assuming it is coming from trackball
				
				// Turn the ENTER of the trackball into a space to better simulate
				// joystick suppot.
				keyCode = Keyboard.SPACE;
				
				// Press and release the key
				fc64.pressKey( keyCode );
				setTimeout( fc64.releaseKey, FC64_CPU_KEY_REGISTER_DELAY, keyCode );
			}
			else
			{
				// Too much of a delay between presses and not ENTER, so this is probably
				// a long press and release on maybe the menu key or something.  We
				// can ignore it.
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
//			if ( isPortrait )
//			{
//				fpsDisplay.text = event.frameTime + " ms/frame " + event.fps + " fps";
//			}
//			else
//			{
//				fpsDisplay.text = event.frameTime + " ms\n  /frame\n\n" + event.fps + " fps";
//			}
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
//			loadProgram( ByteArray( e.target.data ) );
//			software.enabled = true;
//			software.selectedIndex = -1;
//			loadButton.enabled = false;
//			state = "normal";
		}
		
		/**
		 *
		 */
		private function loadProgram( ba:ByteArray ):void
		{
			// get start address
			ba.endian = Endian.LITTLE_ENDIAN;
			var startAddress:int = ba.readShort();
			
			// copy contents
			var addr:int = startAddress;
			for ( var i:uint = 0x02; i < ba.length; i++ )
			{
				fc64.mem.write( addr++, ba[ i ] );
			}
			
			if ( startAddress == 0x0801 )
			{
				// run command
				var charsInBuffer:uint = fc64.mem.read( 0xc6 );
				if ( charsInBuffer < fc64.mem.read( 0x0289 ) - 4 )
				{
					var keyboardBuffer:uint = 0x0277 + charsInBuffer + 1;
					fc64.mem.write( keyboardBuffer++, 82 ); // R
					fc64.mem.write( keyboardBuffer++, 85 ); // U
					fc64.mem.write( keyboardBuffer++, 78 ); // N
					fc64.mem.write( keyboardBuffer++, 13 ); // Return
					fc64.mem.write( 0xc6, charsInBuffer + 5 );
				}
			}
			else
			{
				fc64.cpu.pc = startAddress;
			}
		}
	
//		private function onOSInitialized( event:OSInitializedEvent ):void
//		{
//		}
	}
}

