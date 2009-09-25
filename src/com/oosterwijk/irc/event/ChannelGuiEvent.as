/*
Action Script 3/Flex IRC Client Implementation 
Copyright (C) 2007 Leon Oosterwijk

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
	import com.oosterwijk.irc.User;
	import com.oosterwijk.irc.error.IrcError;

	/**
	 * The ChannelEvent is an IrcEvent that pertains to Channel related activity.
	 * You should inspect the type property to extract the exact type of event
	 * represented by a ChannelEvent object.
	 */
	public class ChannelGuiEvent extends IrcEvent
	{
		public static var KICK_USER_EVENT:String = "kickUser";		
		public static var BAN_USER_EVENT:String = "banUser";		
		public static var KICK_AND_BAN_USER_EVENT:String = "kickAndBanUser";		
		public static var OP_USER_EVENT:String = "opUser";		
		public static var DE_OP_USER_EVENT:String = "deOpUser";		
		public static var VOICE_USER_EVENT:String = "voiceUser";		
		public static var DE_VOICE_USER_EVENT:String = "deVoiceUser";		
		
		private var _channel:String = "";
		private var _username:String = "";
		private var _hostmask:String = "";
		
		public function ChannelGuiEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public function set channel(value:String):void
		{
			this._channel = value;
		}
		public function get channel():String
		{
			return this._channel;
		}

		
		public function set username(value:String):void
		{
			this._username= value;
		}
		public function get username():String
		{
			return this._username;
		}

		public function set hostmask(value:String):void
		{
			this._hostmask= value;
		}
		public function get hostmask():String
		{
			return this._hostmask;
		}
	}
}