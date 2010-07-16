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
 */

package commands
{
	import mx.managers.PopUpManager;
	import mx.core.Application;
	import flash.display.DisplayObject;
	import mx.core.IFlexDisplayObject;
	
	public class DebugCommand implements ICommand
	{
		public function execute():void
		{
			var application:Application = Application.application as Application;
			
			// Loop over the popups currently being displayed.  There should only
			// be 1 debug window, so if we find it in the popup list we'll focus
			// it and then bail out instead of creating another one.
			//
			// TODO: Use popUpChildren instead of rawChildren here?  popUpChildren seems
			// to always report 1.. maybe that's a bug, or maybe I was trying to use it wrong?
			for ( var i:int = 0; i < application.systemManager.rawChildren.numChildren; i++ )
			{
				var popup:IFlexDisplayObject = application.systemManager.rawChildren.getChildAt( i ) as IFlexDisplayObject;
				if ( popup is DebugWindow )
				{
					PopUpManager.bringToFront( popup );
					return;
				}
			}
			
			PopUpManager.createPopUp( application, DebugWindow );
			
			// TODO: Add listeners so the debugger "works"
		}
	}
}