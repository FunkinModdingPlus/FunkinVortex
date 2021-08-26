package;

/**
 * An abstract to make working with raw note data easier
 */
@:build(ArrayAbstractMacro.buildAbstract())
abstract NoteData(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic>
{
	public var strumTime:Float;
	public var noteDirection:Int;
	public var sustainLength:Null<Float>;
	public var altNote:Any;
	public var isLiftNote:Null<Bool>;
	public var healMultiplier:Null<Float>;
	public var damageMultiplier:Null<Float>;
	public var consistentHealth:Null<Bool>;
	public var timingMultiplier:Null<Float>;
	public var shouldBeSung:Null<Bool>;
	public var ignoreHealthMods:Null<Bool>;
	public var animSuffix:Any;
}
