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
package storage.formats
{
	import flash.utils.ByteArray;
	
	import storage.LByteArray;
	
	public interface Storable
	{
		function readImage( data:ByteArray ):Boolean;
		function writeImage():LByteArray;
		
		function getImageDetails():String;
		
		function getImageName():String;
		function getImageType():LByteArray;
		function getImageID():LByteArray;
		function getImageVersion():int;
		
		function setImageName(name:String):void;
		function setImageVersion(ver:int):void;
		
		function getDirectory():Array;
		function getDirectoryEntry( entryNum:int ):Object;
		function addEntry( entry:Object ):Boolean;
		function delEntry( index:int ):void;

		function getProgram( entry:Object ):LByteArray;		
		function getSector( t:int, s:int ):LByteArray;
		
		function setErrorBytes( b:LByteArray ):void;
		function getErrorBytes():LByteArray;
		function setExtendedData( b:LByteArray ):void;
		function getExtendedData():LByteArray;
	}
}