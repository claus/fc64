/*
 * Copyright notice
 *
 * (c) 2010 Robert Eaglestone.  All rights reserved.
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
package c64.storage
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import mx.core.UIComponent;
	
	import c64.storage.formats.D16;
	import c64.storage.formats.D40;
	import c64.storage.formats.D64;
	import c64.storage.formats.D65;
	import c64.storage.formats.D81;
	import c64.storage.formats.D82;
	import c64.storage.formats.LDA;
	import c64.storage.formats.PRG;
	import c64.storage.formats.R64;
	import c64.storage.formats.SKP;
	import c64.storage.formats.Storable;
	import c64.storage.formats.T64;
	
	public class StorageFactory extends UIComponent
	{		
		public static var IMG_LOADED:String = "imgLoaded";
		
		public var translator:Storable;
		private var loader:URLLoader = new URLLoader();
		private var callback:Function;
		
		public function StorageFactory()
		{
		}
		
		public function load( name:String, callback:Function ):void
		{
			translator = getTranslator( name );	
			this.callback = callback;
			
			var request:URLRequest = new URLRequest( name );
			request.contentType = "application/octet-stream";
			request.requestHeaders = new Array(new URLRequestHeader("Content-Type", "application/octet-stream"));
			
			// response.addHeader(“Cache-Control”,”no-cache, no-store, must-revalidate”); 
			
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener( Event.COMPLETE, onFileLoaded );
			loader.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
			loader.load( request );		
		}
		
		private function onIOError( event:ErrorEvent ):void
		{
			trace( event );
		}
		
		public function readImage( filename:String, data:ByteArray ):Storable
		{
			translator = getTranslator( filename );	
			translator.readImage( data );
			return translator;
		}
		
		private function onFileLoaded( event:Event ):void
		{
			var data:ByteArray = ByteArray(event.target.data);
			data.endian = Endian.LITTLE_ENDIAN; 
			translator.readImage( data );
			
			if ( callback != null )
				callback();
		}
		
		public function getTranslator( filename:String ):Storable
		{
			var fileparts:Array = filename.split( /[\/\.]/ );
			var fileExt:String = fileparts.pop().toString();	
			var imgName:String = fileparts.pop().toString();
			
			switch( fileExt.toUpperCase() )
			{
				case 'D16': return new D16( imgName );   // 16.0 m
				case 'D40': return new D40( imgName );   // 400 k
				case 'D64': return new D64( imgName );   // 170 k
				case 'D65': return new D65( imgName );   // 1.9 m
//				case 'D71': return new D71( imgName );   // 340 k
				case 'D81': return new D81( imgName );   // 800 k
				case 'D82': return new D82( imgName );   // 1.0 m
				case 'D8250': return new D82( imgName ); // ??
				
				case 'LDA': return new LDA( imgName );   // variable
				case 'PRG':                              // variable
				case 'P00': return new PRG( imgName );   // variable
				case 'R64': return new R64( imgName );   // variable
				case 'SKP': return new SKP( imgName );   // variable
				case 'T64': return new T64( imgName );   // variable
//				case 'G64': return new G64();
				
				default: throw new Error( "UNKNOWN IMAGE TYPE: " + fileExt ); 
			}
			return null;
		}		
	}
}


