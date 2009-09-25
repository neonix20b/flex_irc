/*
Action Script 3/Flex IRC Client Implementation 
Copyright (C) 2007 Leon Oosterwijk
Based on PircBot by Paul James Mutton (http://www.jibble.org/)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

package com.oosterwijk.irc.event
{
	import flash.events.Event;
	
	/**
	 * the IrcEvent is the base class for the various IRC-related events in this package.
	 */
	public class IrcEvent extends Event
	{
		public function IrcEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}