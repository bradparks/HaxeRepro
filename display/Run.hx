package display;

import haxe.macro.Compiler;

using sys.io.File;
using haxe.Json;

/**
 * Run with `haxe -x display.Run -D port=XXXXX` from the root of HaxeRepro.
 * Port is used as an argument for `--connect XXXXX`.
 * Default port is 60000.
 */
class Run {
	static public function main() {
		var connectArgs = ['--connect', getPort()];
		var i = 0;
		for (set in readDisplayArgs()) {
			Sys.println('|> Executing arguments #${++i} from display/output.log:${set.line} ...');
			Sys.command('haxe', connectArgs.concat(set.args));
		}
		Sys.println('|> Done.');
	}

	static function getPort():String {
		var port = Compiler.getDefine('port');
		return (port == null ? '60000' : port);
	}

	static function readDisplayArgs():Array<{line:Int, args:Array<String>}> {
		var result = [];
		var data = 'display/output.log'.getContent().split('\n');
		for (line in 0...data.length) {
			var rawData = data[line];
			if (rawData.indexOf('Processing Arguments [') != 0) {
				continue;
			}
			rawData = rawData.substring(rawData.indexOf('[') + 1, rawData.lastIndexOf(']'));

			var jsonPos = rawData.indexOf('{');
			var args = if (jsonPos == -1) {
				fixVersionPaths(rawData.split(','));
			} else {
				var args = fixVersionPaths(rawData.substr(0, jsonPos).split(','));
				var display:DisplayJson = rawData.substr(jsonPos).parse();
				if (display.params != null && display.params.file != null) {
					display.params.contents = display.params.file.getContent();
				}
				args.concat([display.stringify()]);
			}
			result.push({
				line: line + 1,
				args: args
			});
		}
		return result;
	}

	/**
	 * If `-cp` arg value contains a path to haxelib with version number, it would look like `/path/to/haxelib/actuate/1,2,0`
	 * But `args` is generated by splitting an arguments string with coma: `"-cp,/path/to/haxelib/actuate/1,2,0".split(',')`,
	 * which breaks such paths.
	 * This function restores arguments like `/path/to/haxelib/actuate/1,2,0`
	 */
	static function fixVersionPaths(args:Array<String>):Array<String> {
		var result = [];
		var idx = -1;
		for (a in args) {
			switch Std.parseInt(a) {
				case null:
					result[++idx] = a;
				case n:
					result[idx] += ',$n';
			}
		}
		return result;
	}
}

typedef DisplayJson = {
	jsonrpc:String,
	id:Int,
	method:String,
	?params:{
		?file:String,
		?contents:String,
		?offset:Int
	}
}
