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
	 * The UserEvent is an IrcEvent that pertains to user related activity.
	 * You should inspect the type property to extract the exact type of event
	 * represented by a UserEvent object.
	 */
	public class UserEvent extends Event
	{
		
		private var _sender:String = "";
		private var _login:String = "";
		private var _hostname:String = "";
		private var _message:String = "";
		private var _target:String = "";
		private var _newNick:String = "";
		private var _mode:String = "";
		private var _response:String = "";
		
		public function UserEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/** 
		 * the nick of the user who initiated this event.
		 */		
		public function set sender(value:String):void
		{
			this._sender= value;
		}
		public function get sender():String
		{
			return this._sender;
		}

		/**
		 * the login to which this event pertains
		 */
		public function set login(value:String):void
		{
			this._login= value;
		}
		public function get login():String
		{
			return this._login;
		}

		/**
		 * the hostname of the originator of this event.
		 */
		public function set hostname(value:String):void
		{
			this._hostname = value;
		}
		public function get hostname():String
		{
			return this._hostname;
		}

		/**
		 * the message of this event. could be private message, etc.
		 */
		public function set message(value:String):void
		{
			this._message= value;
		}
		public function get message():String
		{
			return this._message;
		}

		/**
		 * the nick affected by the event. (the nick that is kicked for instances)
		 */
		public function set targetNick(value:String):void
		{
			this._target= value;
		}
		public function get targetNick():String
		{
			return this._target;
		}

		/**
		 * used by rename events to store the new nickname for a user
		 */
		public function set newNick(value:String):void
		{
			this._newNick= value;
		}
		public function get newNick():String
		{
			return this._newNick;
		}

		/**
		 * the mode of this event. used by the onUserMode event to store the new mode of a user.
		 */
		public function set mode(value:String):void
		{
			this._mode = value;
		}
		public function get mode():String
		{
			return this._mode;
		}
		
	}
}