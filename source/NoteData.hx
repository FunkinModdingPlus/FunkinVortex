package;

/**
 * An abstract to make working with raw note data easier
 */
abstract NoteData(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic>
{
	public var strumTime(get, set):Float;

	function get_strumTime():Float
	{
		return this[0];
	}

	function set_strumTime(value:Float):Float
	{
		return this[0] = value;
	}

	public var noteDirection(get, set):Int;

	function get_noteDirection():Int
	{
		return this[1];
	}

	function set_noteDirection(value:Int):Int
	{
		return this[1] = value;
	}

	public var sustainLength(get, set):Null<Float>;

	function get_sustainLength():Null<Float>
	{
		return this[2];
	}

	function set_sustainLength(value:Null<Float>):Null<Float>
	{
		return this[2] = value;
	}

	public var altNote(get, set):Any;

	function set_altNote(value:Any):Any
	{
		return this[3] = value;
	}

	function get_altNote():Any
	{
		return this[3];
	}

	public var isLiftNote(get, set):Null<Bool>;

	function get_isLiftNote():Null<Bool>
	{
		return this[4];
	}

	function set_isLiftNote(value:Null<Bool>):Null<Bool>
	{
		return this[4] = value;
	}

	public var healMultiplier(get, set):Null<Float>;

	function get_healMultiplier():Null<Float>
	{
		return this[5];
	}

	function set_healMultiplier(value:Null<Float>):Null<Float>
	{
		return this[5] = value;
	}

	public var damageMultiplier(get, set):Null<Float>;

	function get_damageMultiplier():Null<Float>
	{
		return this[6];
	}

	function set_damageMultiplier(value:Null<Float>):Null<Float>
	{
		return this[6] = value;
	}

	public var consistentHealth(get, set):Null<Bool>;

	function get_consistentHealth():Null<Bool>
	{
		return this[7];
	}

	function set_consistentHealth(value:Null<Bool>):Null<Bool>
	{
		return this[7] = value;
	}

	public var timingMultiplier(get, set):Null<Float>;

	function get_timingMultiplier():Null<Float>
	{
		return this[8];
	}

	function set_timingMultiplier(value:Null<Float>):Null<Float>
	{
		return this[8] = value;
	}

	public var shouldBeSung(get, set):Null<Bool>;

	function get_shouldBeSung():Null<Bool>
	{
		return this[9];
	}

	function set_shouldBeSung(value:Null<Bool>):Null<Bool>
	{
		return this[9] = value;
	}

	public var ignoreHealthMods(get, set):Null<Bool>;

	function get_ignoreHealthMods():Null<Bool>
	{
		return this[10];
	}

	function set_ignoreHealthMods(value:Null<Bool>):Null<Bool>
	{
		return this[10] = value;
	}

	public var animSuffix(get, set):Any;

	function set_animSuffix(value:Any):Any
	{
		return this[11] = value;
	}

	function get_animSuffix():Any
	{
		return this[11];
	}
}
