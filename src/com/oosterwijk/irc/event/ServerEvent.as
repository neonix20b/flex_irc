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
	 * The ServerEvent is an IrcEvent that pertains to global server related activity.
	 * You should inspect the type property to extract the exact type of event
	 * represented by a ServerEvent object.
	 */
	public class ServerEvent extends IrcEvent
	{
		private var _code:int = 0;
		private var _response:String = "";
		
		public function ServerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * the code of the irc-server generated message.
		 */
		public function set code(value:int):void
		{
			this._code= value;
		}
		public function get code():int
		{
			return this._code;
		}


		public function set response(value:String):void
		{
			this._response = value;
		}
		public function get response():String
		{
			return this._response;
		}
		
		
	}
}