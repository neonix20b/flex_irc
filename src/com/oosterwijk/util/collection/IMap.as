/*
 Copyright (c) 2006 Eric J. Feminella  <eric@ericfeminella.com>
 All rights reserved.
  
 Permission is hereby granted, free of charge, to any person obtaining a copy 
 of this software and associated documentation files (the "Software"), to deal 
 in the Software without restriction, including without limitation the rights 
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is furnished 
 to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all 
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 @ignore
 */
package com.oosterwijk.util.collection
{
    /**
     * Defines the contract for HashMap implementations
     */
    public interface IMap
    {
        /**
         * Adds a key / value to the current Map
         */
        function put(key:String, value:*):void

        /**
         * Removes a key / value from the current Map
         */
        function remove(key:String):void
        
        /**
         * Returns a key value from the current Map
         */
        function getValue(key:String):*
        
        /**
         * Determines if a key exists in the current map
         */
        function containsKey(key:String):Boolean
        
        /**
         * Determines if a value exists in the current map
         */
        function containsValue(value:*):Boolean

        /**
         * Return an array of all the keys in the map.
         */
        function keys():Array
                
        /**
         * Return an array of all the values in the map.
         */
        function values():Array
                
        /**
         * Returns the size of this map
         */
        function size():int
        
        /**
         * Determines if the current map is empty
         */
        function isEmpty():Boolean
        
        
        /**
         * Resets all key / values in map to null
         */
        function clear():void
    }

}