package funkin.macros;

#if macro
import funkin.ClientPrefs;

import haxe.macro.Context;
import haxe.macro.Expr;

using funkin.macros.Sowy;

class OptionMacro
{
	public static macro function build():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		var pos = Context.currentPos();

		var optionNames:Array<String> = [];
		var definitions:Map<String, OptionData> = ClientPrefs.getOptionDefinitions(); // gets all the option definitions

		// defining this here cause it'd start type checking the options map for some reason
		fields.push({
			name: "_optionDefinitions",
			access: [APrivate, AStatic],
			kind: FVar(macro : Map<String, OptionData>, macro $v{definitions}),
			pos: pos
		});
		fields.findByName("getOptionDefinitions").kind = FFun({
			args: [],
			expr: macro { return ClientPrefs._optionDefinitions.copy(); },
			ret: macro : Map<String, OptionData>
		});

		for(option => key in definitions){
			var optionField:Null<Field> = fields.findByName(option);
			if (optionField != null){
				// if (optionField.access.contains(AStatic))
					continue;
			}

			optionNames.push(option);
			switch(key.type){
				case Toggle:
					var defVal:Bool = key.value == null ? false : key.value;
					fields.push({
						name: option,
						access: [APublic, AStatic],
						kind: FVar(macro :Bool, macro $v{defVal}),
						pos: pos
					});
				case Dropdown:
					var defVal:String = key.value == null ? key.data.get("options")[0] : key.value;
					fields.push({
						name: option,
						access: [APublic, AStatic],
						kind: FVar(macro :String, macro $v{defVal}),
						pos: pos
					});
				case Number:
					var defVal:Float = key.value == null ? 0 : key.value;
					fields.push({
						name: option,
						access: [APublic, AStatic],
						kind: FVar(macro:Float, macro $v{defVal}),
						pos: pos
					});

				default:
					// nothing
			}

		}

		fields.push({
			name: 'options',
			access: [APublic, AStatic],
			kind: FVar(macro :Array<String>, macro $v{optionNames}),
			pos: pos
		});

		return fields;
	}
}
#end