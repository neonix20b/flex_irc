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

package com.oosterwijk.irc
{
	import com.oosterwijk.irc.event.ChannelEvent;
	import com.oosterwijk.irc.event.ServerEvent;
	import com.oosterwijk.irc.event.UserEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;


[Event(name="connectEvent",type="com.oosterwijk.event.ServerEvent")]
[Event(name="disconnectEvent",type="com.oosterwijk.event.ServerEvent")]
[Event(name="serverResponseEvent",type="com.oosterwijk.event.ServerEvent")]
[Event(name="nickAlreadyInUseEvent",type="com.oosterwijk.event.ServerEvent")]
[Event(name="ircConnectionErrorEvent",type="com.oosterwijk.event.ServerEvent")]
[Event(name="securityConnectionErrorEvent",type="com.oosterwijk.event.ServerEvent")]
[Event(name="privateMessageEvent",type="com.oosterwijk.event.UserEvent")]
[Event(name="actionEvent",type="com.oosterwijk.event.UserEvent")]
[Event(name="noticeEvent",type="com.oosterwijk.event.UserEvent")]
[Event(name="nickChangeEvent",type="com.oosterwijk.event.UserEvent")]
[Event(name="userModeEvent",type="com.oosterwijk.event.UserEvent")]
[Event(name="quitEvent",type="com.oosterwijk.event.UserEvent")]
[Event(name="inviteEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="userListEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="messageEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="joinEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="partEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="kickEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="topicEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="channelInfoEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="modeEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="opEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="deopEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="voiceEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="deVoiceEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="setChannelKeyEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="removeChannelKeyEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="setChannelLimitEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="removeChannelLimitEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="setChannelBanEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="removeChannelBanEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="setTopicProtectionEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="removeTopicProtectionEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="setNoExternalMessagesEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="removeNoExternalMessagesEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="setInviteOnlyEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="removeInviteOnlyEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="setModeratedEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="removeModeratedEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="setPrivateEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="removePrivateEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="setSecretEvent",type="com.oosterwijk.event.ChannelEvent")]
[Event(name="removeSecretEvent",type="com.oosterwijk.event.ChannelEvent")]
	/**
	 * This class implements a Flex-based IRC Client. This class Translates the
	 * 'On<i>IrcEvent</i>() methods from the AsIrcClient Class into Flex Events.
	 * The evens are divided into three classes. ServerEvent,UserEvent and ChannelEvent.
	 * Each event will be set with a type indicating the exact nature of the irc event that occurred
	 * The events will also have properties set relevant to that particular operation. for a list of all
	 * the properties that are set for each action, look at the 'On<i>IrcEvent</i>() methods below.
	 * 
	 * @see AsIrcClient
	 */
	public class FlexIrcClient extends AsIrcClient implements IEventDispatcher
	{
		
		/* ================= PRIVATE VARIABLES ===============================*/
		private var _eventDispatcher:IEventDispatcher = new EventDispatcher();
		
		/* ================= STATIC VARIABLES ===============================*/
		static public var CONNECT_EVENT:String = "connectEvent";
		static public var DISCONNECT_EVENT:String = "disconnectEvent";
		static public var NICK_ALREADY_IN_USE_EVENT:String = "nickAlreadyInUseEvent";
		static public var IRC_CONNECTION_ERROR_EVENT:String = "ircConnectionErrorEvent";
		static public var SECURITY_CONNECTION_ERROR_EVENT:String = "securityConnectionErrorEvent";
		static public var SERVER_RESPONSE_EVENT:String = "serverResponseEvent";
		static public var PRIVATE_MESSAGE_EVENT:String = "privateMessageEvent";
		static public var ACTION_EVENT:String = "actionEvent";
		static public var NOTICE_EVENT:String = "noticeEvent";
		static public var NICK_CHANGE_EVENT:String = "nickChangeEvent";
		static public var QUIT_EVENT:String = "quitEvent";
		static public var USER_MODE_EVENT:String = "userModeEvent";
		static public var INVITE_EVENT:String = "inviteEvent";
		static public var USER_LIST_EVENT:String = "userListEvent";
		static public var MESSAGE_EVENT:String = "messageEvent";
		static public var JOIN_EVENT:String = "joinEvent";
		static public var PART_EVENT:String = "partEvent";
		static public var KICK_EVENT:String = "kickEvent";
		static public var TOPIC_EVENT:String = "topicEvent";
		static public var CHANNEL_INFO_EVENT:String = "channelInfoEvent";
		static public var MODE_EVENT:String = "modeEvent";
		static public var OP_EVENT:String = "opEvent";
		static public var DE_OP_EVENT:String = "deopEvent";
		static public var VOICE_EVENT:String = "voiceEvent";
		static public var DE_VOICE_EVENT:String = "deVoiceEvent";
		static public var SET_CHANNEL_KEY_EVENT:String = "setChannelKeyEvent";
		static public var REMOVE_CHANNEL_KEY_EVENT:String = "removeChannelKeyEvent";
		static public var SET_CHANNEL_LIMIT_EVENT:String = "setChannelLimitEvent";
		static public var REMOVE_CHANNEL_LIMIT_EVENT:String = "removeChannelLimitEvent";
		static public var SET_CHANNEL_BAN_EVENT:String = "setChannelBanEvent";
		static public var REMOVE_CHANNEL_BAN_EVENT:String = "removeChannelBanEvent";
		static public var SET_TOPIC_PROTECTION_EVENT:String = "setTopicProtectionEvent";
		static public var REMOVE_TOPIC_PROTECTION_EVENT:String = "removeTopicProtectionEvent";
		static public var SET_NO_EXTERNAL_MESSAGES_EVENT:String = "setNoExternalMessagesEvent";
		static public var REMOVE_NO_EXTERNAL_MESSAGES_EVENT:String = "removeNoExternalMessagesEvent";
		static public var SET_INVITE_ONLY_EVENT:String = "setInviteOnlyEvent";
		static public var REMOVE_INVITE_ONLY_EVENT:String = "removeInviteOnlyEvent";
		static public var SET_MODERATED_EVENT:String = "setModeratedEvent";
		static public var REMOVE_MODERATED_EVENT:String = "removeModeratedEvent";
		static public var SET_PRIVATE_EVENT:String = "setPrivateEvent";
		static public var REMOVE_PRIVATE_EVENT:String = "removePrivateEvent";
		static public var SET_SECRET_EVENT:String = "setSecretEvent";
		static public var REMOVE_SECRECT_EVENT:String = "removeSecretEvent";
		
		
		/* ================= IEventDispatcher METHODS =========================*/
		/**
		 * @see flash.events.IEventDispatcher#hasEventListener
		 */
		public function hasEventListener(type:String):Boolean
		{
			return this._eventDispatcher.hasEventListener(type);
		}
		
		/**
		 * @see flash.events.IEventDispatcher#willTrigger()
		 */
		public function willTrigger(type:String):Boolean
		{
			return this._eventDispatcher.willTrigger(type);
		}
		
		/**
		 * @see flash.events.IEventDispatcher#addEventListener()
		 */
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0.0, useWeakReference:Boolean=false):void
		{
			this._eventDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		/**
		 * @see flash.events.IEventDispatcher#removeEventListener()
		 */
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			this._eventDispatcher.removeEventListener(type, listener, useCapture);
		}
		
		/**
		 * @see flash.events.IEventDispatcher#dispatchEvent()
		 */
		public function dispatchEvent(event:Event):Boolean
		{
			return this._eventDispatcher.dispatchEvent(event);
		}

		/* ================= AsIrcClient METHODS ==----=======================*/

		/* Server Related Events */

		/**
		 * Dispatches a new ServerEvent when called.
		 * @see AsIrcClient#onServerResponse()
		 * @see #CONNECT_EVENT
		 */
	    protected   override function onConnect():void 
	    {
	    	var event:ServerEvent = new ServerEvent(FlexIrcClient.CONNECT_EVENT);
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ServerEvent when called.
		 * @see AsIrcClient#onDisconnect()
		 * @see #DISCONNECT_EVENT
		 */
	    protected   override function onDisconnect():void 
	    {
	    	var event:ServerEvent = new ServerEvent(FlexIrcClient.DISCONNECT_EVENT);
	    	this.dispatchEvent(event);
	    }
	    
	    
	    /**
	    * Dispatches a new ServerEvent when called.
	    * @see AsIrcClient#onNickNAmeAlreadyInUse()
	    * @see #NICK_ALREADY_IN_USE_EVENT
	    */
	    protected override function onNickNameAlreadyInUse():void
	    {
	    	var event:ServerEvent = new ServerEvent(FlexIrcClient.NICK_ALREADY_IN_USE_EVENT);
	    	this.dispatchEvent(event);	    	
	    }
	    
	    /**
	    * Dispatches a new ServerEvent when called. sets the event.response property to the 
	    * response received from the server.
	    * @see AsIrcClient#onConnectionError()
	    * @see #IRC_CONNECTION_ERROR_EVENT
	    */
	    protected override function onConnectionError(line:String):void
	    {
	    	var event:ServerEvent = new ServerEvent(FlexIrcClient.IRC_CONNECTION_ERROR_EVENT);
	    	event.response = line;
	    	this.dispatchEvent(event);	    	
	    }
	    protected override function onSecurityError(line:String):void
	    {
	    	var event:ServerEvent = new ServerEvent(FlexIrcClient.SECURITY_CONNECTION_ERROR_EVENT);
	    	event.response = line;
	    	this.dispatchEvent(event);	    	
	    }
	    

		/**
		 * Dispatches a new ServerEvent when called.
		 * @param code becomes property 'code' on event.
		 * @param response becomes property 'response' on event.
		 * @see AsIrcClient#onServerResponse()
		 * @see #SERVER_RESPONSE_EVENT
		 */
	    protected   override function onServerResponse(code:int,  response:String):void 
	    {
	    	var event:ServerEvent = new ServerEvent(FlexIrcClient.SERVER_RESPONSE_EVENT);
	    	event.code = code;
	    	event.response = response;
	    	this.dispatchEvent(event);
	    }

		/* User Related Events */

		/**
		 * Dispatches a new UserEvent when called.
		 * @param sender becomes property 'sender' on event.
		 * @param login becomes property 'login' on event.
		 * @param hostname becomes property 'hostname' on event.
		 * @param message becomes property 'message' on event.
		 * @see AsIrcClient#onPrivateMessage()
		 * @see #PRIVATE_MESSAGE_EVENT
		 */
	    protected   override function onPrivateMessage(sender:String, login:String,hostname:String,message:String):void 
	    {
	    	var event:UserEvent = new UserEvent(FlexIrcClient.PRIVATE_MESSAGE_EVENT);
	    	event.sender = sender;
	    	event.login = login;
	    	event.hostname = hostname;
	    	event.message = message;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new UserEvent when called.
		 * @param sender becomes property 'sender' on event.
		 * @param login becomes property 'login' on event.
		 * @param hostname becomes property 'hostname' on event.
		 * @param target becomes property 'targetNick' on event.
		 * @param action becomes property 'message' on event.
		 * @see AsIrcClient#onAction()
		 * @see #ACTION_EVENT
		 */
	    protected   override function onAction(sender:String, login:String,hostname:String,target:String, action:String):void
	    {
	    	var event:UserEvent = new UserEvent(FlexIrcClient.ACTION_EVENT);
	    	event.sender = sender;
	    	event.login = login;
	    	event.hostname = hostname;
	    	event.targetNick = target;
	    	event.message = action;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new UserEvent when called.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourchHostname becomes property 'hostname' on event.
		 * @param target becomes property 'targetNick' on event.
		 * @param notice becomes property 'message' on event.
		 * @see AsIrcClient#onNotice()
		 * @see #NOTICE_EVENT
		 */
	    protected   override function onNotice(sourceNick:String, sourceLogin:String,sourceHostname:String,target:String,notice:String):void
	    {
	    	var event:UserEvent = new UserEvent(FlexIrcClient.NOTICE_EVENT);
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.targetNick = target;
	    	event.message = notice;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new UserEvent when called.
		 * @param oldNick becomes property 'sender' on event.
		 * @param login becomes property 'login' on event.
		 * @param hostname becomes property 'hostname' on event.
		 * @param newNick becomes property 'newNick' on event.
		 * @see AsIrcClient#onNickChange()
		 * @see #NICK_CHANGE_EVENT
		 */
	    protected   override function onNickChange(oldNick:String, login:String, hostname:String,newNick:String):void
	    {
	    	var event:UserEvent = new UserEvent(FlexIrcClient.NICK_CHANGE_EVENT);
	    	event.sender = oldNick;
	    	event.login = login;
	    	event.hostname = hostname;
	    	event.newNick = newNick;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new UserEvent when called.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param reason becomes property 'message' on event.
		 * @see AsIrcClient#onQuit()
		 * @see #QUIT_EVENT
		 */
	    protected   override function onQuit(sourceNick:String, sourceLogin:String,sourceHostname:String,reason:String):void
	    {
	    	var event:UserEvent = new UserEvent(FlexIrcClient.QUIT_EVENT);
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.message = reason;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new UserEvent when called.
		 * @param targetNick becomes property 'targetNick' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param mode becomes property 'mode' on event.
		 * @see AsIrcClient#onQuit()
		 * @see #QUIT_EVENT
		 */
	    protected   override function onUserMode(targetNick:String, sourceNick:String, sourceLogin:String, sourceHostname:String, mode:String):void
	    {
	    	var event:UserEvent = new UserEvent(FlexIrcClient.USER_MODE_EVENT);
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.mode = mode;
	    	event.targetNick = targetNick;
	    	this.dispatchEvent(event);
	    }
	    

		/* Channel Related Events */

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param targetNick becomes property 'targetNick' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param channel becomes property 'channel' on event.
		 * @see AsIrcClient#onInvite()
		 * @see #INVITE_EVENT
		 */
	    protected  override  function onInvite(targetNick:String, sourceNick:String, sourceLogin:String, sourceHostname:String, channel:String):void      
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.INVITE_EVENT);
	    	event.targetNick = targetNick;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.channel = channel;
	    	this.dispatchEvent(event);
	    }


		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param users becomes property 'users' on event.
		 * @see AsIrcClient#onUserList()
		 * @see #USER_LIST_EVENT
		 */
	    protected  override  function onUserList(channel:String, users:Array):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.USER_LIST_EVENT);
	    	event.channel = channel;
	    	event.users = users;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sender becomes property 'sender' on event.
		 * @param login becomes property 'login' on event.
		 * @param hostname becomes property 'hostname' on event.
		 * @param message becomes property 'message' on event.
		 * @see AsIrcClient#onMessage()
		 * @see #MESSAGE_EVENT
		 */
	    protected  override  function onMessage( channel:String, sender:String, login:String,hostname:String,message:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.MESSAGE_EVENT);
	    	event.channel = channel;
	    	event.sender = sender;
	    	event.login = login;
	    	event.hostname = hostname;
	    	event.message = message;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sender becomes property 'sender' on event.
		 * @param login becomes property 'login' on event.
		 * @param hostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onJoin()
		 * @see #JOIN_EVENT
		 */
	    protected  override  function onJoin(channel:String, sender:String,login:String,hostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.JOIN_EVENT);
	    	event.channel = channel;
	    	event.sender = sender;
	    	event.login = login;
	    	event.hostname = hostname;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sender becomes property 'sender' on event.
		 * @param login becomes property 'login' on event.
		 * @param hostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onPart()
		 * @see #PART_EVENT
		 */
	    protected  override  function onPart(channel:String, sender:String, login:String,hostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.PART_EVENT);
	    	event.channel = channel;
	    	event.sender = sender;
	    	event.login = login;
	    	event.hostname = hostname;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param kickerNick becomes property 'sender' on event.
		 * @param kickerLogin becomes property 'login' on event.
		 * @param kickerHostname becomes property 'hostname' on event.
		 * @param recipientNick becomes property 'targetNick' on event.
		 * @see AsIrcClient#onKick()
		 * @see #KICK_EVENT
		 */
	    protected  override  function onKick(channel:String, kickerNick:String,kickerLogin:String,kickerHostname:String, recipientNick:String, reason:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.KICK_EVENT);
	    	event.channel = channel;
	    	event.sender = kickerNick;
	    	event.login = kickerLogin;
	    	event.hostname = kickerHostname;
	    	event.targetNick = recipientNick;
	    	event.message = reason;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param setBy becomes property 'sender' on event.
		 * @param topic becomes property 'message' on event.
		 * @param date becomes property 'date' on event.
		 * @param changed becomes property 'changed' on event.
		 * @see AsIrcClient#onTopic()
		 * @see #TOPIC_EVENT
		 */
	    protected  override  function onTopic(channel:String, topic:String,setBy:String=null, date:Number=0, changed:Boolean=false):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.TOPIC_EVENT);
	    	event.channel = channel;
	    	event.sender = setBy;
	    	event.message = topic;
	    	event.date = date;
	    	event.changed = changed;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param userCount becomes property 'userCount' on event.
		 * @param topic becomes property 'message' on event.
		 * @see AsIrcClient#onChannelInfo()
		 * @see #CHANNEL_INFO_EVENT
		 */
	    protected  override  function onChannelInfo( channel:String, userCount:int, topic:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.CHANNEL_INFO_EVENT);
	    	event.channel = channel;
	    	event.userCount = userCount;
	    	event.message = topic;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param mode becomes property 'mode' on event.
		 * @see AsIrcClient#onMode()
		 * @see #MODE_EVENT
		 */
	    protected  override  function onMode(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, mode:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.MODE_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.mode = mode;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param recipient becomes property 'targetNick' on event.
		 * @see AsIrcClient#onOp()
		 * @see #OP_EVENT
		 */
	    protected  override  function onOp(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, recipient:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.OP_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.targetNick = recipient;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param recipient becomes property 'targetNick' on event.
		 * @see AsIrcClient#onDeOp()
		 * @see #DE_OP_EVENT
		 */
	    protected  override  function onDeop(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, recipient:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.DE_OP_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.targetNick = recipient;
	    	this.dispatchEvent(event);
	    }
	
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param recipient becomes property 'targetNick' on event.
		 * @see AsIrcClient#onVoice()
		 * @see #VOICE_EVENT
		 */
	    protected  override  function onVoice(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, recipient:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.VOICE_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.targetNick = recipient;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param recipient becomes property 'targetNick' on event.
		 * @see AsIrcClient#onDeVoice()
		 * @see #DE_VOICE_EVENT
		 */
	    protected  override  function onDeVoice(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, recipient:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.DE_VOICE_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.targetNick = recipient;
	    	this.dispatchEvent(event);
	    }
	
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param key becomes property 'message' on event.
		 * @see AsIrcClient#onSetChannelKey()
		 * @see #SET_CHANNEL_KEY_EVENT
		 */
	    protected  override  function onSetChannelKey(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, key:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.SET_CHANNEL_KEY_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.message = key;
	    	this.dispatchEvent(event);
	    }
	
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param key becomes property 'message' on event.
		 * @see AsIrcClient#onRemoveChannelKey()
		 * @see #REMOVE_CHANNEL_KEY_EVENT
		 */
	    protected  override  function onRemoveChannelKey(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, key:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.REMOVE_CHANNEL_KEY_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.message = key;
	    	this.dispatchEvent(event);
	    }
	
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param limit becomes property 'limit' on event.
		 * @see AsIrcClient#onSetChannelLimit()
		 * @see #SET_CHANNEL_LIMIT_EVENT
		 */
	    protected  override  function onSetChannelLimit(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, limit:int):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.SET_CHANNEL_LIMIT_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.limit = limit;
	    	this.dispatchEvent(event);
	    }
	
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param limit becomes property 'limit' on event.
		 * @see AsIrcClient#onRemoveChannelLimit()
		 * @see #REMOVE_CHANNEL_LIMIT_EVENT
		 */
	    protected  override  function onRemoveChannelLimit(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.REMOVE_CHANNEL_LIMIT_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }
	
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param hostmask becomes property 'hostmask' on event.
		 * @see AsIrcClient#onSetChannelBan()
		 * @see #SET_CHANNEL_BAN_EVENT
		 */
	    protected  override  function onSetChannelBan(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, hostmask:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.SET_CHANNEL_BAN_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.hostmask= hostmask;
	    	this.dispatchEvent(event);
	    }
	
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @param hostmask becomes property 'hostmask' on event.
		 * @see AsIrcClient#onRemoveChannelBan()
		 * @see #REMOVE_CHANNEL_BAN_EVENT
		 */
	    protected  override  function onRemoveChannelBan(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, hostmask:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.REMOVE_CHANNEL_BAN_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	event.hostmask= hostmask;
	    	this.dispatchEvent(event);
	    }
	
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onSetTopicProtection()
		 * @see #SET_TOPIC_PROTECTION_EVENT
		 */
	    protected  override  function onSetTopicProtection(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.SET_TOPIC_PROTECTION_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }
	    
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onRemoveTopicProtection()
		 * @see #REMOVE_TOPIC_PROTECTION_EVENT
		 */
	    protected  override  function onRemoveTopicProtection(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.REMOVE_TOPIC_PROTECTION_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }
	    
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onSetNoExternalMessages()
		 * @see #SET_NO_EXTERNAL_MESSAGES_EVENT
		 */
	    protected  override  function onSetNoExternalMessages(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.SET_NO_EXTERNAL_MESSAGES_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }
	    
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onRemoveNoExternalMessages()
		 * @see #REMOVE_NO_EXTERNAL_MESSAGES_EVENT
		 */
	    protected  override  function onRemoveNoExternalMessages(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.REMOVE_NO_EXTERNAL_MESSAGES_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }
	    
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onSetInviteOnly()
		 * @see #SET_INVITE_ONLY_EVENT
		 */
	    protected  override  function onSetInviteOnly(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.SET_INVITE_ONLY_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }
	    
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onRemoveInviteOnly()
		 * @see #REMOVE_INVITE_ONLY_EVENT
		 */
	    protected  override  function onRemoveInviteOnly(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.REMOVE_INVITE_ONLY_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }
	    
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onSetModerated()
		 * @see #SET_MODERATED_EVENT
		 */
	    protected  override  function onSetModerated(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.SET_MODERATED_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }
	    
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onRemoveModerated()
		 * @see #REMOVE_MODERATED_EVENT
		 */
	    protected  override  function onRemoveModerated(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.REMOVE_MODERATED_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }
	    
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onSetPrivate()
		 * @see #SET_PRIVATE_EVENT
		 */
	    protected  override  function onSetPrivate(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.SET_PRIVATE_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }
	    
		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onRemovePrivate()
		 * @see #REMOVE_PRIVATE_EVENT
		 */
	    protected  override  function onRemovePrivate(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.REMOVE_PRIVATE_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }
	    

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onSetSecret()
		 * @see #SET_SECRET_EVENT
		 */
	    protected  override  function onSetSecret(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.SET_SECRET_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }

		/**
		 * Dispatches a new ChannelEvent when called.
		 * @param channel becomes property 'channel' on event.
		 * @param sourceNick becomes property 'sender' on event.
		 * @param sourceLogin becomes property 'login' on event.
		 * @param sourceHostname becomes property 'hostname' on event.
		 * @see AsIrcClient#onRemoveSecret()
		 * @see #REMOVE_SECRET_EVENT
		 */
	    protected  override  function onRemoveSecret(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void 
   	    {
	    	var event:ChannelEvent = new ChannelEvent(FlexIrcClient.REMOVE_SECRECT_EVENT);
	    	event.channel = channel;
	    	event.sender = sourceNick;
	    	event.login = sourceLogin;
	    	event.hostname = sourceHostname;
	    	this.dispatchEvent(event);
	    }



	}
}