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
	import com.oosterwijk.irc.error.IrcError;
	import com.oosterwijk.util.*;
	import com.oosterwijk.util.collection.HashMap;

	import flash.errors.IOError;
	import flash.events.*;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import mx.controls.Alert;

	/**
	 * <p>The AsIrcClient class is an ActionScript 3 based IRC Client Library.
	 * The class offers support for most IRC features that are easily supported
	 * by the Flash Player 9(+). Because the Flash Player doesn't allow incoming
	 * connections, features such as DCC and ident are not implemented. This means
	 * you might not be able to use this library to connect to an IRC network
	 * that requires ident. </p>
	 *
	 * <p>Because this class is more of less a direct port of the PircBot.java
	 * class written by Paul James Mutton (http://www.jibble.org/) This class
	 * does not leverage the event driven paradigm most Flex applications
	 * should use. To build a Flex application based on this library you should
	 * use the FlexIRCClient class as a base, as it implements event dispatcing etc.
	 * </p>
	 * @see FlexIrcClient
	 * @see http://www.jibble.org
	 */

	public class AsIrcClient
	{
		/* ================= PRIVATE VARIABLES ===============================*/
		private var _server:String;
		private var _port:int;
		private var _password:String;
		private var _socket:Socket;
		private var _status:String              = STATUS_DISCONNECTED;
		private var _readBuffer:String          = "";
		private var _autoNickChange:Boolean     = false;
		private var _verbose:Boolean            = false;
		private var _topics:HashMap             = new HashMap();
		private var _channels:HashMap           = new HashMap();
		private var _finger:String              = "You ought to be arrested for fingering a bot!";
		private var _name:String                = "guestName";
		private var _nick:String                = "guestNick";
		private var _login:String               = "guestLogin";
		private var _version:String             = VERSION + " ox-Bot";


		/* ================= STATIC VARIABLES ===============================*/
		private static var _channelPrefixes:String = "#&+!";

		/**
		 * These static variables hold the statuses that this IRC client can have.
		 */
		public static var STATUS_CONNECTING:String       = "подключение";
		public static var STATUS_HANDLING_CONNECT:String = "обработка соединения";
		public static var STATUS_CONNECTED:String        = "соединен";
		public static var STATUS_DISCONNECTED:String     = "отключен";

		private static var OP_ADD:int        = 1;
		private static var OP_REMOVE:int     = 2;
		private static var VOICE_ADD:int     = 3;
		private static var VOICE_REMOVE:int  = 4;

		private static var  VERSION:String = "0.1";

		/* ================= SOCKET EVENTS ===============================*/

		/**
		 * The Data Event Handler is called when flex tells us there's data waiting to be read.
		 * Reads lines into buffer and calls handleLine
		 */
		private function socketDataEvent(event:Event):void
		{
			if (this._status == AsIrcClient.STATUS_CONNECTING)
			{
				this.log("Проверка соединения");
				verifyConnection(event);
				return;
			}
			// Check to see if the socket has bytes in the stream
			if (this._status != AsIrcClient.STATUS_HANDLING_CONNECT)
			{
				var moreLines:Boolean = true;
				// keep handling lines while we have them to read.
				while (moreLines)
				{
					var line:String = this.readLine();
					if (line == null)
						moreLines = false;
					else
						this.handleLine(line);
				}
			}
		}

		/**
		 *  Called when connection with server is established.
		 */
		private function connectEvent(event:Event):void
		{
			this.log("*** Соединение установлено ***");
			if (_password != null && !_password != "")
			{
				sendRawLine("PASS " + _password);
			}
			var nick:String = this.getName();
			sendRawLine("NICK " + nick);
			sendRawLine("USER " + this.getLogin() + " 8 * :" + this.getVersion());

		}

		/**
		 * called when socket is closed.
		 */
		private function closeEvent(event:Event):void
		{
			this.log("Соединение было закрыто."  + event.toString());
			onDisconnect();
		}

		/**
		 * called when an IO error occurs. at that point we throw an IOError
		 */
		private function ioErrorEvent(event:Event):void
		{
			this.log("An IO error occurred"  + event.toString());
			//throw new IOError(event.toString());
			onConnectionError("An IO error occurred " + event.toString());
		}

		/**
		 * called when a security error occurs.
		 */	
		private function securityErrorEvent(event:Event):void
		{
			this.log("A Security error occurred"  + event.toString());
			//throw new SecurityError(event.toString());
			onSecurityError("A Security error occurred"  + event.toString());
		}


		/* ================= SOCKET FUNCTIONS ===============================*/
		/**
		 * Attempt to connect to the specified IRC server.
		 * @throws IOError if already connected.
		 * @param host The hostname of the server to connect to.
		 * @param port The port to connect to. Defaults to 6667.
		 * @param password The password with which to connect. Defaults to null (no password).
		 */
		public function connect(host:String,port:int=6667,password:String=null):void
		{
			_server = host;
			_port = port;
			_password = password;
			_status   = AsIrcClient.STATUS_CONNECTING;

			if (isConnected()) 
			{
				throw new IOError("Соединение с IRC сервером уже установлено. Сначала отключитесь.");
			}
			// Clear everything we may have know about channels.
			this.removeAllChannels();

			_socket= new Socket();

			// Initialise listeners
			_socket.addEventListener( "connect" , connectEvent , false , 0 );				
			_socket.addEventListener( "close" , closeEvent , false, 0 );
			_socket.addEventListener( "ioError" , ioErrorEvent , false, 0 );
			_socket.addEventListener( "securityError" , securityErrorEvent , false, 0 );
			_socket.addEventListener( "socketData" , socketDataEvent , false , 0 );
			// Connect to the server.
			_socket.connect(_server,_port);

		}


		/**
		 * Reconnects to the IRC server that we were previously connected to.
		 * The same port number and password will be used.
		 *
		 * @throws IrcError This method will throw an IrcError if we have never connected to an IRC server previously.
		 */
		public final function  reconnect():void 
		{
			if (_server == null) 
				throw new IrcError("Cannot reconnect to an IRC server because we were never connected to one previously!");
			disconnect();
			connect(_server, _port, _password);
		}

		/**
		 * This method disconnects from the server cleanly by calling the
		 * quitServer() method.  Providing the Irc client was connected to an
		 * IRC server.
		 */
		public final function  disconnect():void 
		{
			if (isConnected())
			{
				this.quitServer();
				_socket.close();
				this.onDisconnect();
			}
			_status = AsIrcClient.STATUS_DISCONNECTED;
		}

		/**
		 * Sends a raw line to the Irc server. If not connected this method
		 * will just return void.
		 *
		 * @param line The line that will be sent to the server.
		 */
		public function sendRawLine(line:String):void
		{
			if (isConnected() == false)
				return;
			var cookedLine:ByteArray = new ByteArray();
			cookedLine.writeUTFBytes(line + "\r\n");
			// Write ByteArray to socket
			_socket.writeBytes(cookedLine);
			// Flushes any accumulated data in the socket's output buffer and sends it to the server
			_socket.flush();
		}


		/**
		 * Read a line from the socket and stick it in a buffer.
		 * Reads as many lines as are available.
		 */
		protected function readLine():String
		{
			var readBytes:String;
			while (_socket.bytesAvailable)
			{
				readBytes = _socket.readUTFBytes(_socket.bytesAvailable);
				_readBuffer = _readBuffer.concat(readBytes);
			}
			var ret:String;
			var idx:int = _readBuffer.indexOf("\r\n");
			// check if we have a complete line in our read buffer.
			if (idx > -1)
			{
				// read the new line from the buffer
				ret = _readBuffer.substr(0,idx+2);
				// now remove this line from the buffer
				_readBuffer = _readBuffer.slice(idx+2);
				// return line minux the newline.
				return ret.replace("\r\n","");
			}
			return null;
		}


		/**
		 *  Setup the nick verify everyting is OK on initial connect.
		 * 	If successful, set status to connected.
		 */	
		internal function verifyConnection(event:Event):void
		{
			// while we're handling the connect the regular event listener 
			// should ignore the new data arriving on the socket.
			_status = AsIrcClient.STATUS_HANDLING_CONNECT;
			// Read stuff back from the server to see if we connected.
			var line:String = null;
			var tries:int = 1;
			var nick:String = getName();
			while ((line = readLine()) != null) 
			{
				this.handleLine(line);

				var firstSpace:int  = line.indexOf(" ");
				var secondSpace:int = line.indexOf(" ", firstSpace + 1);
				if (secondSpace >= 0) 
				{
					var code:String = line.substring(firstSpace + 1, secondSpace);
					if (code == "004")// We're connected to the server.
						break;
					else if (code == "433") 
					{
						if (this._autoNickChange) 
						{
							tries++;
							nick = getName() + tries;
							this.sendRawLine("NICK " + nick);
						}
						else 
						{
							_socket.close();
							_status = AsIrcClient.STATUS_DISCONNECTED;
							this.onNickNameAlreadyInUse();
							return;
						}
					}
					else if (code.charAt(0) == "5" || code.charAt(0) == "4") 
					{
						_socket.close();
						_status = AsIrcClient.STATUS_DISCONNECTED;
						this.onConnectionError("Could not log into the IRC server: " + line);
						return;
					}
				}
				this.setNick(nick);

			}
			// now the event handler can start handling lines 
			_status = AsIrcClient.STATUS_CONNECTED;
			this.log("Logged onto server.");
			this.onConnect();
		}


		/* ================= IRC PROTOCOL FUNCTIONS ==========================*/

		private function handleLine(line:String):void 
		{
			this.log("attempting to handle: " + line);

			// Check for server pings.
			if (line.search(/PING :/) > -1)
			{
				// Respond to the ping and return immediately.
				this.onServerPing(line.substr(5));
				return;
			}

			var sourceNick:String     = "";
			var sourceLogin:String    = "";
			var sourceHostname:String = "";

			//StringTokenizer tokenizer = new StringTokenizer(line);
			var arrTokens:Array = line.split(" ");
			var lineTokens:Iterable = new ArrayIterator(arrTokens);


			var senderInfo:String = lineTokens.next() as String;
			var command:String =  lineTokens.next() as String;
			var target:String = null;


			var exclamation:int = senderInfo.indexOf("!");
			var at:int = senderInfo.indexOf("@");

			if (senderInfo.charAt(0) == ":")
			{
				if (exclamation > 0 && at > 0 && exclamation < at) 
				{
					sourceNick     = senderInfo.substr(1, exclamation-1);
					sourceLogin    = senderInfo.substring(exclamation+1 , at);
					sourceHostname = senderInfo.substr(at + 1);
				}
				else 
				{

					if (lineTokens.hasNext()) 
					{
						var token:String = command;
						var code:int     = -1;
						var c:Number;
//	                    try 
//	                    {
						c = Number(token);
//	                    }
//	                    catch (e:*) {
//	                        // Keep the existing value.
						if (!isNaN(c))
							code = int(c);
//	                    }

						if (code != -1) 
						{
							var errorStr:String = token;
							var response:String = line.substr(line.indexOf(errorStr, senderInfo.length) + 4, line.length);
							this.processServerResponse(code, response);
							// Return from the method.
							return;
						}
						else 
						{
							// This is not a server response.
							// It must be a nick without login and hostname.
							// (or maybe a NOTICE or suchlike from the server)
							sourceNick = senderInfo;
							target = token;
						}
					}
					else 
					{
						// We don't know what this line means.
						this.onUnknown(line);
						// Return from the method;
						return;
					}

				}
			}

			command = command.toUpperCase();

			if (sourceNick.charAt(0) == ":") 
				sourceNick = sourceNick.substr(1);
			if (target == null) 
				target = lineTokens.next() as String;
			if (target.charAt(0) == ":")
				target = target.substr(1);

			// Check for CTCP requests.
			// TODO: is this the best way to check fo CTCP?
			if (command == "PRIVMSG" && line.search(":\u0001") > 0 && line.substr(line.length-1,1)  == "\u0001")
			{
				var request:String = line.substring(line.indexOf(":\u0001") + 2, line.length - 1);
				if (request == "VERSION") 
					this.onVersion(sourceNick, sourceLogin, sourceHostname, target);
				else if (request.search(/ACTION /) > -1)
					this.onAction(sourceNick, sourceLogin, sourceHostname, target, request.substring(7));
				else if (request.search(/PING /) > -1 ) 
					this.onPing(sourceNick, sourceLogin, sourceHostname, target, request.substring(5));
				else if (request == "TIME") 
					this.onTime(sourceNick, sourceLogin, sourceHostname, target);
				else if (request == "FINGER" ) 
					this.onFinger(sourceNick, sourceLogin, sourceHostname, target);
				else if ( (request.split(" ").length >= 5) && request.split(" ").shift() == "DCC" ) 
				{
					this.onUnsupportedRequest("DCC is currently not implemented");
				}
				else // An unknown CTCP message - ignore it.
					this.onUnknown(line);
			}
			else if (command == "PRIVMSG" && _channelPrefixes.indexOf(target.charAt(0)) >= 0)  // This is a normal message to a channel.
				this.onMessage(target, sourceNick, sourceLogin, sourceHostname, line.substring(line.indexOf(" :") + 2));
			else if (command == "PRIVMSG") // This is a private message to us.
				this.onPrivateMessage(sourceNick, sourceLogin, sourceHostname, line.substring(line.indexOf(" :") + 2));
			else if (command == "JOIN") 
			{
				// Someone is joining a channel.
				var channel:String = target;
				this.addUser(channel, new User("", sourceNick));
				this.onJoin(channel, sourceNick, sourceLogin, sourceHostname);
			}
			else if (command == "PART") 
			{
				// Someone is parting from a channel.
				this.removeUser(sourceNick,target);
				if (sourceNick == this.getNick()) 
					this.removeChannel(target);
				this.onPart(target, sourceNick, sourceLogin, sourceHostname);
			}
			else if (command == "NICK") 
			{
				// Somebody is changing their nick.
				var newNick:String = target;
				this.renameUser(sourceNick, newNick);
				if (sourceNick == this.getNick()) // Update our nick if it was us that changed nick.
					this.setNick(newNick);
				this.onNickChange(sourceNick, sourceLogin, sourceHostname, newNick);
			}
			else if (command == "NOTICE") // Someone is sending a notice.
				this.onNotice(sourceNick, sourceLogin, sourceHostname, target, line.substring(line.indexOf(" :") + 2));
			else if (command == "QUIT") 
			{
				// Someone has quit from the IRC server.
				if (sourceNick == this.getNick()) 
					this.removeAllChannels();
				else 
					this.removeUser(sourceNick);
				this.onQuit(sourceNick, sourceLogin, sourceHostname, line.substring(line.indexOf(" :") + 2));
			}
			else if (command == "KICK") 
			{
				// Somebody has been kicked from a channel.
				var recipient:String = lineTokens.next() as String;
				this.removeUser(recipient,target);
				if (recipient == this.getNick()) 
					this.removeChannel(target);
				this.onKick(target, sourceNick, sourceLogin, sourceHostname, recipient, line.substring(line.indexOf(" :") + 2));
			}
			else if (command == "MODE") 
			{
				// Somebody is changing the mode on a channel or user.
				var mode:String = line.substring(line.indexOf(target, 2) + target.length + 1);
				if (mode.charAt(0) == ":") 
					mode = mode.substring(1);
				this.processMode(target, sourceNick, sourceLogin, sourceHostname, mode);
			}
			else if (command == "TOPIC") // Someone is changing the topic.
				this.onTopic(target, line.substring(line.indexOf(" :") + 2), sourceNick, new Date().time, true);
			else if (command == "INVITE") // Somebody is inviting somebody else into a channel.
				this.onInvite(target, sourceNick, sourceLogin, sourceHostname, line.substring(line.indexOf(" :") + 2));
			else 
			{
				// If we reach this point, then we've found something that the Irc Client
				// Doesn't currently deal with.
				this.onUnknown(line);
			}

		}

		/**
		 * This method is called by the Irc Client when a numeric response
		 * is received from the IRC server.  We use this method to
		 * allow the Irc Client to process various responses from the server
		 * before then passing them on to the onServerResponse method.
		 *
		 * @param code The three-digit numerical code for the response.
		 * @param response The full response from the IRC server.
		 */
		private final function processServerResponse(code:int , response:String):void 
		{
			var firstSpace:int  = 0;
			var secondSpace:int = 0;
			var thirdSpace:int  = 0;
			var colon:int  		= 0;
			var channel:String  = "";
			var topic:String    = "";
			var arrResponse:Array = null;
			var responseIterator:ArrayIterator = null;

			if (code == ReplyConstants.RPL_LIST) 
			{
				// This is a bit of information about a channel.
				firstSpace = response.indexOf(' ');
				secondSpace = response.indexOf(' ', firstSpace + 1);
				thirdSpace = response.indexOf(' ', secondSpace + 1);
				colon  = response.indexOf(':');
				channel = response.substring(firstSpace + 1, secondSpace);
				var userCount:int  = 0;
				try {

					userCount = int(response.substring(secondSpace + 1, thirdSpace));
				}
				catch (e:Error) {
					// Stick with the value of zero.
				}
				topic = response.substring(colon + 1);
				this.onChannelInfo(channel, userCount, topic);
			}
			else if (code == ReplyConstants.RPL_TOPIC) 
			{
				// This is topic information about a channel we've just joined.
				firstSpace = response.indexOf(' ');
				secondSpace = response.indexOf(' ', firstSpace + 1);
				colon = response.indexOf(':');
				channel = response.substring(firstSpace + 1, secondSpace);
				topic = response.substring(colon + 1);
				_topics.put(channel, topic);
				// For backwards compatibility only - this onTopic method is deprecated.
				this.onTopic(channel, topic);
			}
			else if (code == ReplyConstants.RPL_TOPICINFO) 
			{
				arrResponse = response.split(" ");
				responseIterator = new ArrayIterator(arrResponse);
				responseIterator.next();
				channel = responseIterator.next() as String;
				var setBy:String   = responseIterator.next() as String;
				var date:Number = 0;
				try {
					date = Number((responseIterator.next() as String)) * 1000;
				}
				catch (e:Error) {
					// Stick with the default value of zero.
				}

				topic =  _topics.getValue(channel) as String;
				_topics.remove(channel);

				this.onTopic(channel, topic, setBy, date, false);
			}
			else if (code == ReplyConstants.RPL_NAMREPLY) 
			{
				// This is a list of nicks in a channel that we've just joined.
				var channelEndIndex:int = response.indexOf(" :");
				channel = response.substring(response.lastIndexOf(' ', channelEndIndex - 1) + 1, channelEndIndex);

				arrResponse = (response.substring(response.indexOf(" :") + 2)).split(" ");
				responseIterator = new ArrayIterator(arrResponse);
				while (responseIterator.hasNext()) 
				{
					var nick:String = responseIterator.next() as String;
					var prefix:String = "";
					if (nick.charAt(0) == "@") 
					{
						// User is an operator in this channel.
						prefix = "@";
					}
					else if (nick.charAt(0) == "+") 
					{
						// User is voiced in this channel.
						prefix = "+";
					}
					else if (nick.charAt(0) == ".") 
					{
						// Some wibbly status I've never seen before...
						prefix = ".";
					}
					nick = nick.substring(prefix.length);
					this.addUser(channel, new User(prefix, nick));
				}
			}
			else if (code == ReplyConstants.RPL_ENDOFNAMES) 
			{
				// This is the end of a NAMES list, so we know that we've got
				// the full list of users in the channel that we just joined. 
				channel = response.substring(response.indexOf(' ') + 1, response.indexOf(" :"));
				var users:Array = this.getUsers(channel);
				this.onUserList(channel, users);
			}

			this.onServerResponse(code, response);
		}



		/**
		 * Called when the mode of a channel is set.  We process this in
		 * order to call the appropriate onOp, onDeop, etc method before
		 * finally calling the override-able onMode method.
		 *
		 * @param target The channel or nick that the mode operation applies to.
		 * @param sourceNick The nick of the user that set the mode.
		 * @param sourceLogin The login of the user that set the mode.
		 * @param sourceHostname The hostname of the user that set the mode.
		 * @param mode  The mode that has been set.
		 */
		private final function processMode(target:String, sourceNick:String,sourceLogin:String,sourceHostname:String,mode:String):void
		{
			if (_channelPrefixes.indexOf(target.charAt(0)) >= 0) 
			{
				// The mode of a channel is being changed.
				var channel:String = target;
				var params:Array = mode.split(" ");

				var pn:String = ' ';
				var p:int = 1;
				var i:int = 0;
				// All of this is very large and ugly, but it's the only way of providing
				// what the users want :-/
				for (i = 0; i < (params[0] as String).length; i++) 
				{
					var atPos:String = (params[0] as String).charAt(i);

					if (atPos == '+' || atPos == '-') 
						pn = atPos;
					else if (atPos == 'o') 
					{
						if (pn == '+') 
						{
							this.updateUser(channel, OP_ADD, params[p]);
							onOp(channel, sourceNick, sourceLogin, sourceHostname, params[p]);
						}
						else 
						{
							this.updateUser(channel, OP_REMOVE, params[p]);
							onDeop(channel, sourceNick, sourceLogin, sourceHostname, params[p]);
						}
						p++;
					}
					else if (atPos == 'v') 
					{
						if (pn == '+') 
						{
							this.updateUser(channel, VOICE_ADD, params[p]);
							onVoice(channel, sourceNick, sourceLogin, sourceHostname, params[p]);
						}
						else 
						{
							this.updateUser(channel, VOICE_REMOVE, params[p]);
							onDeVoice(channel, sourceNick, sourceLogin, sourceHostname, params[p]);
						}
						p++; 
					}
					else if (atPos == 'k') 
					{
						if (pn == '+') 
							onSetChannelKey(channel, sourceNick, sourceLogin, sourceHostname, params[p]);
						else 
							onRemoveChannelKey(channel, sourceNick, sourceLogin, sourceHostname, params[p]);
						p++;
					}
					else if (atPos == 'l') 
					{
						if (pn == '+') 
						{
							onSetChannelLimit(channel, sourceNick, sourceLogin, sourceHostname, int(params[p]));
							p++;
						}
						else 
							onRemoveChannelLimit(channel, sourceNick, sourceLogin, sourceHostname);
					}
					else if (atPos == 'b') 
					{
						if (pn == '+') 
							onSetChannelBan(channel, sourceNick, sourceLogin, sourceHostname,params[p]);
						else 
							onRemoveChannelBan(channel, sourceNick, sourceLogin, sourceHostname, params[p]);
						p++;
					}
					else if (atPos == 't') 
					{
						if (pn == '+') 
							onSetTopicProtection(channel, sourceNick, sourceLogin, sourceHostname);
						else 
							onRemoveTopicProtection(channel, sourceNick, sourceLogin, sourceHostname);
					}
					else if (atPos == 'n') 
					{
						if (pn == '+') 
							onSetNoExternalMessages(channel, sourceNick, sourceLogin, sourceHostname);
						else 
							onRemoveNoExternalMessages(channel, sourceNick, sourceLogin, sourceHostname);
					}
					else if (atPos == 'i') 
					{
						if (pn == '+') 
							onSetInviteOnly(channel, sourceNick, sourceLogin, sourceHostname);
						else 
							onRemoveInviteOnly(channel, sourceNick, sourceLogin, sourceHostname);
					}
					else if (atPos == 'm') 
					{
						if (pn == '+') 
							onSetModerated(channel, sourceNick, sourceLogin, sourceHostname);
						else 
							onRemoveModerated(channel, sourceNick, sourceLogin, sourceHostname);
					}
					else if (atPos == 'p') 
					{
						if (pn == '+') 
							onSetPrivate(channel, sourceNick, sourceLogin, sourceHostname);
						else 
							onRemovePrivate(channel, sourceNick, sourceLogin, sourceHostname);
					}
					else if (atPos == 's') 
					{
						if (pn == '+') 
							onSetSecret(channel, sourceNick, sourceLogin, sourceHostname);
						else 
							onRemoveSecret(channel, sourceNick, sourceLogin, sourceHostname);
					}
				}

				this.onMode(channel, sourceNick, sourceLogin, sourceHostname, mode);
			}
			else 
			{
				// The mode of a user is being changed.
				var nick:String = target;
				this.onUserMode(nick, sourceNick, sourceLogin, sourceHostname, mode);
			}
		}


		/**
		 * When you connect to a server and your nick is already in use and
		 * this is set to true, a new nick will be automatically chosen.
		 * This is done by adding numbers to the end of the nick until an
		 * available nick is found.
		 *
		 * @param autoNickChange Set to true if you want automatic nick changes
		 *                       during connection.
		 */
		public function  setAutoNickChange(autoNickChange:Boolean):void
		{
			_autoNickChange = autoNickChange;
		}

		/**
		 * Joins a channel.
		 *
		 * @param channel The name of the channel to join (eg "#cs").
		 * @param key They key needed to join the channel. Defaults to null.
		 */
		public final function  joinChannel(channel:String, key:String = null ):void
		{
			if (key == null)
				this.sendRawLine("JOIN " + channel);
			else
				this.sendRawLine("JOIN " + channel + " " + key);

		}

		/**
		 * Parts (leaves) a channel, giving an optional reason.
		 *
		 * @param channel The name of the channel to leave.
		 * @param reason  The reason for parting the channel. Defaults to null
		 */
		public final function partChannel(channel:String , reason:String=null ):void
		{
			if (reason != null)
				this.sendRawLine("PART " + channel + " :" + reason);
			else
				this.sendRawLine("PART " + channel);
		}


		/**
		 * Quits from the IRC server with an optional reason.
		 * Providing we are actually connected to an IRC server, the
		 * onDisconnect() method will be called as soon as the IRC server
		 * disconnects us.
		 *
		 * @param reason The reason for quitting the server.
		 */
		public final function  quitServer(reason:String = null):void 
		{
			if (reason == null)
				this.quitServer("");
			else
				this.sendRawLine("QUIT :" + reason);
		}



		/**
		 * Sends a message to a channel or a private message to a user.
		 *  <p>
		 * Some examples: -
		 *  <pre>    // Send the message "Hello!" to the channel #cs.
		 *    sendMessage("#cs", "Hello!");
		 *
		 *    // Send a private message to Paul that says "Hi".
		 *    sendMessage("Paul", "Hi");</pre>
		 *
		 *
		 * @param target The name of the channel or user nick to send to.
		 * @param message The message to send.
		 *
		 */
		public final function sendMessage(target:String,  message:String):void
		{
			this.sendRawLine("PRIVMSG " + target + " :" + message);
		}


		/**
		 * Sends an action to the channel or to a user.
		 *
		 * @param target The name of the channel or user nick to send to.
		 * @param action The action to send.
		 *
		 */
		public final function sendAction(target:String , action:String ):void 
		{
			sendCTCPCommand(target, "ACTION " + action);
		}


		/**
		 * Sends a notice to the channel or to a user.
		 *
		 * @param target The name of the channel or user nick to send to.
		 * @param notice The notice to send.
		 */
		public final function sendNotice(target:String , notice:String ):void 
		{
			this.sendRawLine("NOTICE " + target + " :" + notice);
		}


		/**
		 * Sends a CTCP command to a channel or user.  (Client to client protocol).
		 * Examples of such commands are "PING <number>", "FINGER", "VERSION", etc.
		 * For example, if you wish to request the version of a user called "Dave",
		 * then you would call <code>sendCTCPCommand("Dave", "VERSION");</code>.
		 * The type of response to such commands is largely dependant on the target
		 * client software.
		 *
		 * @param target The name of the channel or user to send the CTCP message to.
		 * @param command The CTCP command to send.
		 */
		public final function sendCTCPCommand( target:String,  command:String):void 
		{
			this.sendRawLine("PRIVMSG " + target + " :\u0001" + command + "\u0001");
		}


		/**
		 * Attempt to change the current nick (nickname) of the bot when it
		 * is connected to an IRC server.
		 * After confirmation of a successful nick change, the getNick method
		 * will return the new nick.
		 *
		 * @param newNick The new nick to use.
		 */
		public final function changeNick(newNick:String):void 
		{
			this.sendRawLine("NICK " + newNick);
		}


		/**
		 * Set the mode of a channel.
		 * This method attempts to set the mode of a channel.  This
		 * may require the bot to have operator status on the channel.
		 * For example, if the bot has operator status, we can grant
		 * operator status to "Dave" on the #cs channel
		 * by calling setMode("#cs", "+o Dave");
		 * An alternative way of doing this would be to use the op method.
		 *
		 * @param channel The channel on which to perform the mode change.
		 * @param mode    The new mode to apply to the channel.  This may include
		 *                zero or more arguments if necessary.
		 *
		 * @see #op(String,String) op
		 */
		public final function setMode( channel:String,  mode:String):void 
		{
			this.sendRawLine("MODE " + channel + " " + mode);
		}


		/**
		 * Sends an invitation to join a channel.  Some channels can be marked
		 * as "invite-only", so it may be useful to allow a bot to invite people
		 * into it.
		 *
		 * @param nick    The nick of the user to invite
		 * @param channel The channel you are inviting the user to join.
		 *
		 */
		public final function sendInvite(nick:String , channel:String ):void 
		{
			this.sendRawLine("INVITE " + nick + " :" + channel);
		}    


		/**
		 * Bans a user from a channel.  An example of a valid hostmask is
		 * "*!*compu@*.18hp.net".  This may be used in conjunction with the
		 * kick method to permanently remove a user from a channel.
		 * Successful use of this method may require the bot to have operator
		 * status itself.
		 *
		 * @param channel The channel to ban the user from.
		 * @param hostmask A hostmask representing the user we're banning.
		 */
		public final function ban( channel:String,  hostmask:String):void 
		{
			this.sendRawLine("MODE " + channel + " +b " + hostmask);
		}


		/**
		 * Unbans a user from a channel.  An example of a valid hostmask is
		 * "*!*compu@*.18hp.net".
		 * Successful use of this method may require the bot to have operator
		 * status itself.
		 *
		 * @param channel The channel to unban the user from.
		 * @param hostmask A hostmask representing the user we're unbanning.
		 */
		public final function unBan(channel:String , hostmask:String ):void 
		{
			this.sendRawLine("MODE " + channel + " -b " + hostmask);
		}


		/**
		 * Grants operator privilidges to a user on a channel.
		 * Successful use of this method may require the bot to have operator
		 * status itself.
		 *
		 * @param channel The channel we're opping the user on.
		 * @param nick The nick of the user we are opping.
		 */
		public final function op(channel:String , nick:String ):void 
		{
			this.setMode(channel, "+o " + nick);
		}


		/**
		 * Removes operator privilidges from a user on a channel.
		 * Successful use of this method may require the bot to have operator
		 * status itself.
		 *
		 * @param channel The channel we're deopping the user on.
		 * @param nick The nick of the user we are deopping.
		 */
		public final function deOp(channel:String , nick:String ):void 
		{
			this.setMode(channel, "-o " + nick);
		}


		/**
		 * Grants voice privilidges to a user on a channel.
		 * Successful use of this method may require the bot to have operator
		 * status itself.
		 *
		 * @param channel The channel we're voicing the user on.
		 * @param nick The nick of the user we are voicing.
		 */
		public final function voice(channel:String , nick:String ):void 
		{
			this.setMode(channel, "+v " + nick);
		}


		/**
		 * Removes voice privilidges from a user on a channel.
		 * Successful use of this method may require the bot to have operator
		 * status itself.
		 *
		 * @param channel The channel we're devoicing the user on.
		 * @param nick The nick of the user we are devoicing.
		 */
		public final function deVoice( channel:String,  nick:String):void 
		{
			this.setMode(channel, "-v " + nick);
		}


		/**
		 * Set the key for a channel.
		 * This method attempts to set the key of a channel.
		 *
		 * @param channel The channel on which to perform the mode change.
		 * @param key   The key for the channel.
		 *
		 */
		public final function setChannelKey(channel:String , key:String ):void 
		{
			this.setMode(channel, "+k " + key);
		}

		/**
		 * Remove the key for a channel.
		 * This method attempts to remove the key of a channel.
		 *
		 * @param channel The channel on which to perform the mode change.
		 * @param key   The key for the channel.
		 *
		 */
		public final function removeChannelKey(channel:String, key:String ):void 
		{
			this.setMode(channel, "-k " + key);
		}


		/**
		 * Set the topic for a channel.
		 * This method attempts to set the topic of a channel.  This
		 * may require the bot to have operator status if the topic
		 * is protected.
		 *
		 * @param channel The channel on which to perform the mode change.
		 * @param topic   The new topic for the channel.
		 *
		 */
		public final function setTopic(channel:String , topic:String ):void 
		{
			this.sendRawLine("TOPIC " + channel + " :" + topic);
		}



		/**
		 * Kicks a user from a channel, giving a reason.
		 * This method attempts to kick a user from a channel and
		 * may require the bot to have operator status in the channel.
		 *
		 * @param channel The channel to kick the user from.
		 * @param nick    The nick of the user to kick.
		 * @param reason  A description of the reason for kicking a user.
		 */
		public final function kick( channel:String,  nick:String,  reason:String=""):void 
		{
			this.sendRawLine("KICK " + channel + " " + nick + " :" + reason);
		}



		/**
		 * Issues a request for a list of all channels on the IRC server.
		 * When the Irc Client receives information for each channel, it will
		 * call the onChannelInfo method, which you will need to override
		 * if you want it to do anything useful.
		 *  <p>
		 * Some IRC servers support certain parameters for LIST requests.
		 * One example is a parameter of ">10" to list only those channels
		 * that have more than 10 users in them.  Whether these parameters
		 * are supported or not will depend on the IRC server software.
		 *
		 * @param parameters The parameters to supply when requesting the
		 *                   list.
		 *
		 * @see #onChannelInfo(String,int,String) onChannelInfo
		 */
		public final function listChannels(parameters:String=null):void
		{
			if (parameters == null) {
				this.sendRawLine("LIST");
			}
			else {
				this.sendRawLine("LIST " + parameters);
			}
		}

		/* ================= CONCRETE OVERRIDABLE FUNCTIONS ==================*/

		/**
		 * This method is called whenever we receive a VERSION request.
		 * This abstract implementation responds with the Irc Client's _version string,
		 * so if you override this method, be sure to either mimic its functionality
		 * or to call super.onVersion(...);
		 *
		 * @param sourceNick The nick of the user that sent the VERSION request.
		 * @param sourceLogin The login of the user that sent the VERSION request.
		 * @param sourceHostname The hostname of the user that sent the VERSION request.
		 * @param target The target of the VERSION request, be it our nick or a channel name.
		 */
		protected function onVersion(sourceNick:String, sourceLogin:String, sourceHostname:String, target:String):void 
		{
			this.sendRawLine("NOTICE " + sourceNick + " :\u0001VERSION " + _version + "\u0001");
		}


		/**
		 * This method is called whenever we receive a PING request from another
		 * user.
		 *  <p>
		 * This abstract implementation responds correctly, so if you override this
		 * method, be sure to either mimic its functionality or to call
		 * super.onPing(...);
		 *
		 * @param sourceNick The nick of the user that sent the PING request.
		 * @param sourceLogin The login of the user that sent the PING request.
		 * @param sourceHostname The hostname of the user that sent the PING request.
		 * @param target The target of the PING request, be it our nick or a channel name.
		 * @param pingValue The value that was supplied as an argument to the PING command.
		 */
		protected function onPing(sourceNick:String, sourceLogin:String, sourceHostname:String, target:String, pingValue:String):void 
		{
			this.sendRawLine("NOTICE " + sourceNick + " :\u0001PING " + pingValue + "\u0001");
		}


		/**
		 * The actions to perform when a PING request comes from the server.
		 *  <p>
		 * This sends back a correct response, so if you override this method,
		 * be sure to either mimic its functionality or to call
		 * super.onServerPing(response);
		 *
		 * @param response The response that should be given back in your PONG.
		 */
		protected function onServerPing(response:String=""):void 
		{
			this.sendRawLine("PONG " + response);
		}


		/**
		 * This method is called whenever we receive a TIME request.
		 *  <p>
		 * This abstract implementation responds correctly, so if you override this
		 * method, be sure to either mimic its functionality or to call
		 * super.onTime(...);
		 *
		 * @param sourceNick The nick of the user that sent the TIME request.
		 * @param sourceLogin The login of the user that sent the TIME request.
		 * @param sourceHostname The hostname of the user that sent the TIME request.
		 * @param target The target of the TIME request, be it our nick or a channel name.
		 */
		protected function onTime(sourceNick:String, sourceLogin:String, sourceHostname:String, target:String):void 
		{
			this.sendRawLine("NOTICE " + sourceNick + " :\u0001TIME " + new Date().toString() + "\u0001");
		}


		/**
		 * This method is called whenever we receive a FINGER request.
		 *  <p>
		 * This abstract implementation responds correctly, so if you override this
		 * method, be sure to either mimic its functionality or to call
		 * super.onFinger(...);
		 *
		 * @param sourceNick The nick of the user that sent the FINGER request.
		 * @param sourceLogin The login of the user that sent the FINGER request.
		 * @param sourceHostname The hostname of the user that sent the FINGER request.
		 * @param target The target of the FINGER request, be it our nick or a channel name.
		 */
		protected function onFinger(sourceNick:String, sourceLogin:String, sourceHostname:String, target:String):void 
		{
			this.sendRawLine("NOTICE " + sourceNick + " :\u0001FINGER " + _finger + "\u0001");
		}




		/**
		 * Called when we receive a request that is currently not implemented.
		 *  <p>
		 * The implementation of this method just does a trace. override if you want more control.
		 */
		protected function onUnsupportedRequest(error:String):void
		{
			trace(error);	
		}
		/* ================= ABSTRACT OVERRIDABLE FUNCTIONS ==================*/

		/**
		 * This method is called whenever we receive a line from the server that
		 * the Irc Client has not been programmed to recognise.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param line The raw line that was received from the server.
		 */
		protected function onUnknown(line:String):void 
		{
			// And then there were none :)
		}

		/**
		 * This method is called once the ircBot has successfully connected to
		 * the IRC server.
		 *  <p>
		 * The implementation of this method in the ircBot abstract class
		 * performs no actions and may be overridden as required.
		 *
		 */
		protected   function onConnect():void {}


		/**
		 * This method carries out the actions to be performed when the ircBot
		 * gets disconnected.  This may happen if the ircBot quits from the
		 * server, or if the connection is unexpectedly lost.
		 *  <p>
		 * Disconnection from the IRC server is detected immediately if either
		 * we or the server close the connection normally. If the connection to
		 * the server is lost, but neither we nor the server have explicitly closed
		 * the connection, then it may take a few minutes to detect (this is
		 * commonly referred to as a "ping timeout").
		 *  <p>
		 * If you wish to get your IRC bot to automatically rejoin a server after
		 * the connection has been lost, then this is probably the ideal method to
		 * override to implement such functionality.
		 *  <p>
		 * The implementation of this method in the ircBot abstract class
		 * performs no actions and may be overridden as required.
		 */
		protected   function onDisconnect():void {}

		/**
		 * Called when we try to connect to a server and the nick we're trying to use is already taken.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 */
		protected function onNickNameAlreadyInUse():void  {}    

		/**
		 * Called when we try to connect to a server and the connection fails.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param line the error message reported by the irc server.
		 *
		 */
		protected function onConnectionError(line:String):void  {}
		protected function onSecurityError(line:String):void {}

		/**
		 * This method is called when we receive a numeric response from the
		 * IRC server.
		 *  <p>
		 * Numerics in the range from 001 to 099 are used for client-server
		 * connections only and should never travel between servers.  Replies
		 * generated in response to commands are found in the range from 200
		 * to 399.  Error replies are found in the range from 400 to 599.
		 *  <p>
		 * For example, we can use this method to discover the topic of a
		 * channel when we join it.  If we join the channel #test which
		 * has a topic of &quot;I am King of Test&quot; then the response
		 * will be &quot;<code>Irc Client #test :I Am King of Test</code>&quot;
		 * with a code of 332 to signify that this is a topic.
		 * (This is just an example - note that overriding the
		 * <code>onTopic</code> method is an easier way of finding the
		 * topic for a channel). Check the IRC RFC for the full list of other
		 * command response codes.
		 *  <p>
		 * Irc Client implements the interface ReplyConstants, which contains
		 * contstants that you may find useful here.
		 *  <p>
		 * The implementation of this method in the ircBot abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param code The three-digit numerical code for the response.
		 * @param response The full response from the IRC server.
		 *
		 * @see ReplyConstants
		 */
		protected   function onServerResponse(code:int,  response:String):void {}


		/**
		 * This method is called when we receive a user list from the server
		 * after joining a channel.
		 *  <p>
		 * Shortly after joining a channel, the IRC server sends a list of all
		 * users in that channel. The Irc Client collects this information and
		 * calls this method as soon as it has the full list.
		 *  <p>
		 * To obtain the nick of each user in the channel, call the getNick()
		 * method on each User object in the array.
		 *  <p>
		 * At a later time, you may call the getUsers method to obtain an
		 * up to date list of the users in the channel.
		 *  <p>
		 * The implementation of this method in the ircBot abstract class
		 * performs no actions and may be overridden as required.
		 *
		 *
		 * @param channel The name of the channel.
		 * @param users An array of User objects belonging to this channel.
		 *
		 * @see User
		 */
		protected   function onUserList(channel:String, users:Array):void {}


		/**
		 * This method is called whenever a message is sent to a channel.
		 *  <p>
		 * The implementation of this method in the ircBot abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel to which the message was sent.
		 * @param sender The nick of the person who sent the message.
		 * @param login The login of the person who sent the message.
		 * @param hostname The hostname of the person who sent the message.
		 * @param message The actual message sent to the channel.
		 */
		protected   function onMessage( channel:String, sender:String, login:String,hostname:String,message:String):void {}


		/**
		 * This method is called whenever a private message is sent to the ircBot.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param sender The nick of the person who sent the private message.
		 * @param login The login of the person who sent the private message.
		 * @param hostname The hostname of the person who sent the private message.
		 * @param message The actual message.
		 */
		protected   function onPrivateMessage(sender:String, login:String,hostname:String,message:String):void {}


		/**
		 * This method is called whenever an ACTION is sent from a user.  E.g.
		 * such events generated by typing "/me goes shopping" in most IRC clients.
		 *  <p>
		 * The implementation of this method in the ircBot abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param sender The nick of the user that sent the action.
		 * @param login The login of the user that sent the action.
		 * @param hostname The hostname of the user that sent the action.
		 * @param target The target of the action, be it a channel or our nick.
		 * @param action The action carried out by the user.
		 */
		protected   function onAction(sender:String, login:String,hostname:String,target:String, action:String):void {}


		/**
		 * This method is called whenever we receive a notice.
		 *  <p>
		 * The implementation of this method in the ircBot abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param sourceNick The nick of the user that sent the notice.
		 * @param sourceLogin The login of the user that sent the notice.
		 * @param sourceHostname The hostname of the user that sent the notice.
		 * @param target The target of the notice, be it our nick or a channel name.
		 * @param notice The notice message.
		 */
		protected   function onNotice(sourceNick:String, sourceLogin:String,sourceHostname:String,target:String,notice:String):void {}


		/**
		 * This method is called whenever someone (possibly us) joins a channel
		 * which we are on.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel which somebody joined.
		 * @param sender The nick of the user who joined the channel.
		 * @param login The login of the user who joined the channel.
		 * @param hostname The hostname of the user who joined the channel.
		 */
		protected  function onJoin(channel:String, sender:String,login:String,hostname:String):void {}


		/**
		 * This method is called whenever someone (possibly us) parts a channel
		 * which we are on.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel which somebody parted from.
		 * @param sender The nick of the user who parted from the channel.
		 * @param login The login of the user who parted from the channel.
		 * @param hostname The hostname of the user who parted from the channel.
		 */
		protected   function onPart(channel:String, sender:String, login:String,hostname:String):void {}


		/**
		 * This method is called whenever someone (possibly us) changes nick on any
		 * of the channels that we are on.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param oldNick The old nick.
		 * @param login The login of the user.
		 * @param hostname The hostname of the user.
		 * @param newNick The new nick.
		 */
		protected   function onNickChange(oldNick:String, login:String, hostname:String,newNick:String):void {}


		/**
		 * This method is called whenever someone (possibly us) is kicked from
		 * any of the channels that we are in.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel from which the recipient was kicked.
		 * @param kickerNick The nick of the user who performed the kick.
		 * @param kickerLogin The login of the user who performed the kick.
		 * @param kickerHostname The hostname of the user who performed the kick.
		 * @param recipientNick The unfortunate recipient of the kick.
		 * @param reason The reason given by the user who performed the kick.
		 */
		protected   function onKick(channel:String, kickerNick:String,kickerLogin:String,kickerHostname:String, recipientNick:String, reason:String):void {}


		/**
		 * This method is called whenever someone (possibly us) quits from the
		 * server.  We will only observe this if the user was in one of the
		 * channels to which we are connected.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param sourceNick The nick of the user that quit from the server.
		 * @param sourceLogin The login of the user that quit from the server.
		 * @param sourceHostname The hostname of the user that quit from the server.
		 * @param reason The reason given for quitting the server.
		 */
		protected   function onQuit(sourceNick:String, sourceLogin:String,sourceHostname:String,reason:String):void {}

		/**
		 * This method is called whenever a user sets the topic, or when
		 * Irc Client joins a new channel and discovers its topic.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel that the topic belongs to.
		 * @param topic The topic for the channel.
		 * @param setBy The nick of the user that set the topic.
		 * @param date When the topic was set (milliseconds since the epoch).
		 * @param changed True if the topic has just been changed, false if
		 *                the topic was already there.
		 *
		 */
		protected   function onTopic(channel:String, topic:String,setBy:String=null, date:Number=0, changed:Boolean=false):void {}


		/**
		 * After calling the listChannels() method in Irc Client, the server
		 * will start to send us information about each channel on the
		 * server.  You may override this method in order to receive the
		 * information about each channel as soon as it is received.
		 *  <p>
		 * Note that certain channels, such as those marked as hidden,
		 * may not appear in channel listings.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The name of the channel.
		 * @param userCount The number of users visible in this channel.
		 * @param topic The topic for this channel.
		 *
		 * @see #listChannels() listChannels
		 */
		protected   function onChannelInfo( channel:String, userCount:int, topic:String):void {}

		/**
		 * Called when the mode of a channel is set.
		 *  <p>
		 * You may find it more convenient to decode the meaning of the mode
		 * string by overriding the onOp, onDeOp, onVoice, onDeVoice,
		 * onChannelKey, onDeChannelKey, onChannelLimit, onDeChannelLimit,
		 * onChannelBan or onDeChannelBan methods as appropriate.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel that the mode operation applies to.
		 * @param sourceNick The nick of the user that set the mode.
		 * @param sourceLogin The login of the user that set the mode.
		 * @param sourceHostname The hostname of the user that set the mode.
		 * @param mode The mode that has been set.
		 *
		 */
		protected   function onMode(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, mode:String):void {}


		/**
		 * Called when the mode of a user is set.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 *
		 * @param targetNick The nick that the mode operation applies to.
		 * @param sourceNick The nick of the user that set the mode.
		 * @param sourceLogin The login of the user that set the mode.
		 * @param sourceHostname The hostname of the user that set the mode.
		 * @param mode The mode that has been set.
		 *
		 */
		protected   function onUserMode(targetNick:String, sourceNick:String, sourceLogin:String, sourceHostname:String, mode:String):void {}



		/**
		 * Called when a user (possibly us) gets granted operator status for a channel.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 * @param recipient The nick of the user that got 'opped'.
		 */
		protected   function onOp(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, recipient:String):void {}


		/**
		 * Called when a user (possibly us) gets operator status taken away.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 * @param recipient The nick of the user that got 'deopped'.
		 */
		protected   function onDeop(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, recipient:String):void {}


		/**
		 * Called when a user (possibly us) gets voice status granted in a channel.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 * @param recipient The nick of the user that got 'voiced'.
		 */
		protected   function onVoice(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, recipient:String):void {}


		/**
		 * Called when a user (possibly us) gets voice status removed.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 * @param recipient The nick of the user that got 'devoiced'.
		 */
		protected   function onDeVoice(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, recipient:String):void {}


		/**
		 * Called when a channel key is set.  When the channel key has been set,
		 * other users may only join that channel if they know the key.  Channel keys
		 * are sometimes referred to as passwords.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 * @param key The new key for the channel.
		 */
		protected   function onSetChannelKey(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, key:String):void {}


		/**
		 * Called when a channel key is removed.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 * @param key The key that was in use before the channel key was removed.
		 */
		protected function onRemoveChannelKey(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, key:String):void {}


		/**
		 * Called when a user limit is set for a channel.  The number of users in
		 * the channel cannot exceed this limit.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 * @param limit The maximum number of users that may be in this channel at the same time.
		 */
		protected function onSetChannelLimit(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, limit:int):void {}


		/**
		 * Called when the user limit is removed for a channel.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onRemoveChannelLimit(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when a user (possibly us) gets banned from a channel.  Being
		 * banned from a channel prevents any user with a matching hostmask from
		 * joining the channel.  For this reason, most bans are usually directly
		 * followed by the user being kicked :-)
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 * @param hostmask The hostmask of the user that has been banned.
		 */
		protected function onSetChannelBan(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, hostmask:String):void {}


		/**
		 * Called when a hostmask ban is removed from a channel.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 * @param hostmask
		 */
		protected function onRemoveChannelBan(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String, hostmask:String):void {}


		/**
		 * Called when topic protection is enabled for a channel.  Topic protection
		 * means that only operators in a channel may change the topic.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onSetTopicProtection(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when topic protection is removed for a channel.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onRemoveTopicProtection(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when a channel is set to only allow messages from users that
		 * are in the channel.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onSetNoExternalMessages(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when a channel is set to allow messages from any user, even
		 * if they are not actually in the channel.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onRemoveNoExternalMessages(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when a channel is set to 'invite only' mode.  A user may only
		 * join the channel if they are invited by someone who is already in the
		 * channel.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onSetInviteOnly(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when a channel has 'invite only' removed.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onRemoveInviteOnly(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when a channel is set to 'moderated' mode.  If a channel is
		 * moderated, then only users who have been 'voiced' or 'opped' may speak
		 * or change their nicks.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onSetModerated(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when a channel has moderated mode removed.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onRemoveModerated(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when a channel is marked as being in private mode.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onSetPrivate(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when a channel is marked as not being in private mode.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onRemovePrivate(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when a channel is set to be in 'secret' mode.  Such channels
		 * typically do not appear on a server's channel listing.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onSetSecret(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when a channel has 'secret' mode removed.
		 *  <p>
		 * This is a type of mode change and is also passed to the onMode
		 * method in the Irc Client class.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param channel The channel in which the mode change took place.
		 * @param sourceNick The nick of the user that performed the mode change.
		 * @param sourceLogin The login of the user that performed the mode change.
		 * @param sourceHostname The hostname of the user that performed the mode change.
		 */
		protected function onRemoveSecret(channel:String, sourceNick:String, sourceLogin:String, sourceHostname:String):void {}


		/**
		 * Called when we are invited to a channel by a user.
		 *  <p>
		 * The implementation of this method in the Irc Client abstract class
		 * performs no actions and may be overridden as required.
		 *
		 * @param targetNick The nick of the user being invited - should be us!
		 * @param sourceNick The nick of the user that sent the invitation.
		 * @param sourceLogin The login of the user that sent the invitation.
		 * @param sourceHostname The hostname of the user that sent the invitation.
		 * @param channel The channel that we're being invited to.
		 */
		protected function onInvite(targetNick:String, sourceNick:String, sourceLogin:String, sourceHostname:String, channel:String):void  {}    


		/**
		 * Sets the verbose mode. If verbose mode is set to true, then log entries
		 * will be traced. The default value is false and
		 * will result in no output. For general development, we strongly recommend
		 * setting the verbose mode to true.
		 *
		 * @param verbose true if verbose mode is to be used.  Default is false.
		 */
		public final function setVerbose(verbose:Boolean):void 
		{
			_verbose = verbose;
		}


		/* ================= SETTER AND GETTER FUNCTIONS ==================*/
		/**
		 * Sets the name of the bot, which will be used as its nick when it
		 * tries to join an IRC server.  This should be set before joining
		 * any servers, otherwise the default nick will be used.
		 *  <p>
		 * The changeNick method should be used if you wish to change your nick
		 * when you are connected to a server.
		 *
		 * @param name The new name of the Bot.
		 */
		public final function setName(name:String):void 
		{
			_name = name;
		}


		/**
		 * Sets the internal nick of the bot.  This is only to be called by the
		 * Irc Client class in response to notification of nick changes that apply
		 * to us.
		 *
		 * @param nick The new nick.
		 */
		private final function setNick(nick:String):void 
		{
			_nick = nick;
		}


		/**
		 * Sets the internal login of the Bot.  This should be set before joining
		 * any servers.
		 *
		 * @param login The new login of the Bot.
		 */
		protected final function setLogin(login:String):void 
		{
			_login = login;
		}


		/**
		 * Sets the internal version of the Bot.  This should be set before joining
		 * any servers.
		 *
		 * @param version The new version of the Bot.
		 */
		protected final function setVersion(version:String):void 
		{
			_version = version;
		}


		/**
		 * Sets the interal finger message.  This should be set before joining
		 * any servers.
		 *
		 * @param finger The new finger message for the Bot.
		 */
		protected final function setFinger(finger:String):void 
		{
			_finger = finger;
		}


		/**
		 * Gets the name of the Irc Client. This is the name that will be used as
		 * as a nick when we try to join servers.
		 *
		 * @return The name of the Irc Client.
		 */
		public final function getName():String 
		{
			return _name;
		}


		/**
		 * Returns the current nick of the bot. Note that if you have just changed
		 * your nick, this method will still return the old nick until confirmation
		 * of the nick change is received from the server.
		 *  <p>
		 * The nick returned by this method is maintained only by the Irc Client
		 * class and is guaranteed to be correct in the context of the IRC server.
		 *
		 * @return The current nick of the bot.
		 */
		public function getNick():String 
		{
			return _nick;
		}


		/**
		 * Gets the internal login of the Irc Client.
		 *
		 * @return The login of the Irc Client.
		 */
		public final function getLogin():String 
		{
			return _login;
		}


		/**
		 * Gets the internal version of the Irc Client.
		 *
		 * @return The version of the Irc Client.
		 */
		public final function getVersion():String 
		{
			return _version;
		}


		/**
		 * Gets the internal finger message of the Irc Client.
		 *
		 * @return The finger message of the Irc Client.
		 */
		public final function getFinger():String
		{
			return _finger;
		}


		/**
		 * Returns whether or not the Irc Client is currently connected to a server.
		 * The result of this method should only act as a rough guide,
		 * as the result may not be valid by the time you act upon it.
		 *
		 * @return True if and only if the Irc Client is currently connected to a server.
		 */
		public final function  isConnected():Boolean 
		{
			return _socket != null && _socket.connected;
		}


		/**
		 * Gets the maximum length of any line that is sent via the IRC protocol.
		 * The IRC RFC specifies that line lengths, including the trailing \r\n
		 * must not exceed 512 bytes.  Hence, there is currently no option to
		 * change this value in Irc Client.  All lines greater than this length
		 * will be truncated before being sent to the IRC server.
		 *
		 * @return The maximum line length (currently fixed at 512)
		 */
		public final function getMaxLineLength():int 
		{
			return 512;
		}



		/**
		 * Returns the name of the last IRC server the Irc Client tried to connect to.
		 * This does not imply that the connection attempt to the server was
		 * successful (we suggest you look at the onConnect method).
		 * A value of null is returned if the Irc Client has never tried to connect
		 * to a server.
		 *
		 * @return The name of the last machine we tried to connect to. Returns
		 *         null if no connection attempts have ever been made.
		 */
		public final function getServer():String 
		{
			return _server;
		}


		/**
		 * Returns the port number of the last IRC server that the Irc Client tried
		 * to connect to.
		 * This does not imply that the connection attempt to the server was
		 * successful (we suggest you look at the onConnect method).
		 * A value of -1 is returned if the Irc Client has never tried to connect
		 * to a server.
		 *
		 * @since Irc Client 0.9.9
		 *
		 * @return The port number of the last IRC server we connected to.
		 *         Returns -1 if no connection attempts have ever been made.
		 */
		public final function getPort():int 
		{
			return _port;
		}


		/**
		 * Returns the last password that we used when connecting to an IRC server.
		 * This does not imply that the connection attempt to the server was
		 * successful (we suggest you look at the onConnect method).
		 * A value of null is returned if the Irc Client has never tried to connect
		 * to a server using a password.
		 *
		 * @since Irc Client 0.9.9
		 *
		 * @return The last password that we used when connecting to an IRC server.
		 *         Returns null if we have not previously connected using a password.
		 */
		public final function getPassword():String 
		{
			return _password;
		}



		/**
		 * Returns a String representation of this object.
		 * You may find this useful for debugging purposes, particularly
		 * if you are using more than one Irc Client instance to achieve
		 * multiple server connectivity.
		 *
		 * @return a String representation of this object.
		 */
		public function toString():String 
		{
			return "Version{" + _version + "}" +
				" Connected{" + isConnected() + "}" +
				" Server{" + _server + "}" +
				" Port{" + _port + "}" +
				" Password{" + _password + "}";
		}

		/* ================= NON OVERRIDABLE IRC FUNCTIONS ==================*/

		/**
		 * Returns an array of all users in the specified channel.
		 *  <p>
		 * There are some important things to note about this method:-
		 * <ul>
		 *  <li>This method may not return a full list of users if you call it
		 *      before the complete nick list has arrived from the IRC server.
		 *  </li>
		 *  <li>If you wish to find out which users are in a channel as soon
		 *      as you join it, then you should override the onUserList method
		 *      instead of calling this method, as the onUserList method is only
		 *      called as soon as the full user list has been received.
		 *  </li>
		 *  <li>This method will return immediately, as it does not require any
		 *      interaction with the IRC server.
		 *  </li>
		 *  <li>The bot must be in a channel to be able to know which users are
		 *      in it.
		 *  </li>
		 * </ul>
		 *
		 * @param channel The name of the channel to list.
		 *
		 * @return An array of User objects. This array is empty if we are not
		 *         in the channel.
		 *
		 * @see #onUserList(String,User[]) onUserList
		 */
		public final function getUsers(channel:String):Array 
		{
			channel = channel.toLowerCase();
			var userArray:Array = new Array();
			var users:HashMap = _channels.getValue(channel) as HashMap;
			if (users != null) 
			{
				return users.values();
			}
			return userArray;
		}


		/**
		 * Returns an array of all channels that we are in.  Note that if you
		 * call this method immediately after joining a new channel, the new
		 * channel may not appear in this array as it is not possible to tell
		 * if the join was successful until a response is received from the
		 * IRC server.
		 *
		 * @return A String array containing the names of all channels that we
		 *         are in.
		 */
		public final function getChannels():Array 
		{
			return _channels.keys();
		}



		/**
		 * Add a user to the specified channel in our memory.
		 * Overwrite the existing entry if it exists.
		 */
		private final function  addUser( channel:String,  user:User):void
		{
			channel = channel.toLowerCase();
			var users:HashMap = _channels.getValue(channel) as HashMap;
			if (users == null) 
			{
				users = new HashMap();
				_channels.put(channel, users);
			}
			users.put(user.getNick(), user);
		}


		/**
		 * Remove a user from the specified channel in our memory.
		 */
		private final function removeUser( nick:String,channel:String =null):User
		{
			var channels:Array = new Array();
			var ret:User;
			if (channel != null)
				channels.push(channel.toLowerCase());
			else
				channels = _channels.keys();
			var user:User = new User("", nick);
			for (var i:int = 0;i < channels.length ; i++)
			{
				var users:HashMap =  _channels.getValue(channels[i]) as HashMap;
				if (users != null && users.containsKey(nick))
				{
					ret = users.getValue(nick);
					users.remove(nick);
				}
			}
			return ret;
		}


		/**
		 * Rename a user if they appear in any of the channels we know about.
		 */
		private final function renameUser( oldNick:String,  newNick:String):void 
		{
			var channels:Array = _channels.keys();
			for (var i:int = 0 ; i < channels.length ; i++)
			{
				var channel:String = channels[i];
				var user:User = this.removeUser(oldNick,channel);
				if (user != null) 
				{
					user = new User(user.getPrefix(), newNick);
					this.addUser(channel, user);
				}
			}
		}


		/**
		 * Removes an entire channel from our memory of users.
		 */
		private final function removeChannel(channel:String ):void 
		{
			channel = channel.toLowerCase();
			_channels.remove(channel);
		}


		/**
		 * Removes all channels from our memory of users.
		 */
		private final function removeAllChannels():void 
		{
			_channels = new HashMap();
		}


		private final function updateUser(channel:String , userMode:int , nick:String ):void 
		{
			channel = channel.toLowerCase();
			var users:HashMap = _channels.getValue(channel) as HashMap;
			var  newUser:User  = null;
			var i:int = 0;
			if (users != null) 
			{
				var arrUsers:Array = users.values();
				for (i = 0 ;i<arrUsers.length ; i++)
				{
//	        		trace (itr);
					var userObj:User = arrUsers[i] as User;
					trace (userObj);
					if (userObj.getNick().toLowerCase() == nick.toLowerCase() ) 
					{
						if (userMode == OP_ADD) 
						{
							if (userObj.hasVoice()) 
								newUser = new User("@+", nick);
							else 
								newUser = new User("@", nick);
						}
						else if (userMode == OP_REMOVE) 
						{
							if(userObj.hasVoice()) 
								newUser = new User("+", nick);
							else 
								newUser = new User("", nick);
						}
						else if (userMode == VOICE_ADD) 
						{
							if(userObj.isOp()) 
								newUser = new User("@+", nick);
							else 
								newUser = new User("+", nick);
						}
						else if (userMode == VOICE_REMOVE) 
						{
							if(userObj.isOp()) 
								newUser = new User("@", nick);
							else 
								newUser = new User("", nick);
						}
					}
				}
			}
			if (newUser != null) 
				users.put(newUser.getNick(), newUser);
			else 
			{
				// just in case ...
				newUser = new User("", nick);
				users.put(newUser.getNick(), newUser);
			}
		}

		/**
		 * This method currently just traces the input line.
		 * Override and redirect or suppress this logging behavior as needed.
		 *
		 * @param line The line to log.
		 */
		public   function log(line:String):void
		{
			if (this._verbose)
				trace(line);
		}


	}
}

