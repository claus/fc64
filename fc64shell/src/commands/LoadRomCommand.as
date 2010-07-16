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
	import mx.core.Application;
	
	public class LoadRomCommand implements ICommand
	{
		public function execute():void
		{
			// TODO: What to do?
			//		Allow the user to enter a URL?
			//		Allow the user to select a file on their local system?
			//		Both - Display a "Load Rom Window" and let them choose?
			
			var shell:FC64Shell = Application.application as FC64Shell;
			//shell.fc64.loadRom( ... );
		}
	}
}