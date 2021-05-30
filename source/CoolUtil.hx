package;

import flixel.FlxSprite;
import lime.system.System;
import lime.utils.Assets;
import openfl.display.BitmapData;
import tjson.TJSON;

using StringTools;

class CoolUtil
{
	public static var fps:Int = 60;

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = FNFAssets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function coolDynamicTextFile(path:String):Array<String>
	{
		return coolTextFile(path);
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function clamp(mini:Float, maxi:Float, value:Float):Float
	{
		return Math.min(Math.max(mini, value), maxi);
	}

	// can either return an array or a dynamic
	public static function parseJson(json:String):Dynamic
	{
		// the reason we do this is to make it easy to swap out json parsers
		return TJSON.parse(json);
	}

	public static function stringifyJson(json:Dynamic, ?fancy:Bool = true):String
	{
		// use tjson to prettify it
		var style:String = if (fancy) 'fancy' else null;
		return TJSON.encode(json, style);
	}

	public static function truncateFloat(number:Float, precision:Int):Float
	{
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round(num) / Math.pow(10, precision);
		return num;
	}
}

class FlxTools
{
	// Load a graphic and ensure it exists
	static public function loadGraphicDynamic(s:FlxSprite, path:String, animated:Bool = false, width:Int = 0, height:Int = 0, unique:Bool = false,
			?key:String):FlxSprite
	{
		var sus:BitmapData = FNFAssets.getBitmapData(path);
		s.loadGraphic(sus, animated, width, height, unique, key);
		return s;
	}
}
