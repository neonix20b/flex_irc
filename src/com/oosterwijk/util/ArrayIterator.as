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
	 * This class implements a java-style Iterator which iterates over
	 * an Array. 
	 */
	public class ArrayIterator implements Iterable
	{
		private var array:Array = null;
		private var i:int = 0;
		/** 
		 * Constructor takes the Array to build the Iterator over
		 * 
		 * @param array The array to iterate over. 
		 */
		public function ArrayIterator(array:Array)
		{
			this.array = array;
			i = 0;
		}
		
		public function hasNext():Boolean
		{
			if (array.length > i) 
				return true;
			return false;
		}
		
		public function next():Object
		{
			return array[i++];
		}
		
	}
}