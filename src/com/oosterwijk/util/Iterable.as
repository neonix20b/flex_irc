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

package com.oosterwijk.util
{
	/**
	 * ActionScript 3 supports push/pop and shift/unshift making
	 * a class like this kind of redundant. It could come in handy for porting
	 * Java code to ActionScript 3 if you didn't want to change up a lot of code 
	 * which reliese on this type of Interface. 
	 */
	public interface Iterable
	{
		/** 
		 * @returns Return the next Object in the Iterator.
		 */
		function next():Object;

		/**
		 * @returns If there are more objects the method returns true.
		 */
		function hasNext():Boolean;

	}
}