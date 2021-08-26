package;

#if macro
class ArrayAbstractMacro
{
	public static function buildAbstract()
	{
		var fields = haxe.macro.Context.getBuildFields();
		var i = 0;
		for (f in fields.copy())
		{
			switch f.kind
			{
				case FVar(ct, _):
					f.kind = FProp('get', 'set', ct);
				case _:
					haxe.macro.Context.error("Unexpected field.", f.pos);
			}
			var get = "get_" + f.name;
			var set = "set_" + f.name;
			var typeDefinition = macro class Dummy
				{
					public inline function $get() return this[$v{i}];

					public inline function $set(v) return this[$v{i}] = v;
				}
			for (field in typeDefinition.fields)
				fields.push(field);
			i++;
		}
		return fields;
	}
}
#end
