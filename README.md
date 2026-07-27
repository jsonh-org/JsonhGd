<img src="https://github.com/jsonh-org/Jsonh/blob/main/IconUpscaled.png?raw=true" width=180>

[![Godot Asset Library](https://img.shields.io/github/v/release/jsonh-org/JsonhGd.svg?label=Godot%20Asset%20Library&logo=godotengine)](https://godotengine.org/asset-library/asset/INSERT_ASSET_LIBRARY_NUMBER_HERE)
[![Godot Asset Store](https://img.shields.io/github/v/release/jsonh-org/JsonhGd.svg?label=Godot%20Asset%20Store&logo=godotengine)](https://store.godotengine.org/asset/joyless/jsonh-gd)

**JSON for Humans.**

JSON is great. Until you miss that trailing comma... or want to use comments. What about multiline strings?
JSONH provides a much more elegant way to write JSON that's designed for humans rather than machines.

Since JSONH is compatible with JSON, any JSONH syntax can be represented with equivalent JSON.

## JsonhGd

JsonhGd is a parser implementation of [JSONH V1 & V2](https://github.com/jsonh-org/Jsonh) for GDScript in Godot 4.

## Example

```jsonh
{
    // use #, // or /**/ comments
    
    // quotes are optional
    keys: without quotes,

    // commas are optional
    isn\'t: {
        that: cool? # yes
    }

    // use multiline strings
	haiku: '''
		Let me die in spring
		  beneath the cherry blossoms
			while the moon is full.
		'''
    
    // compatible with JSON5
    key: 0xDEADCAFE

    // or use JSON
    "old school": 1337
}
```

## Usage

Everything you need is contained within `JsonhReader`:

```gdscript
extends Node

func _ready() -> void:
	var jsonh: String = """
{
    this is: awesome
}
"""
	var element: Variant = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()
	print(element)
```

## Limitations

### No true deferred execution

Since GDScript doesn't have support for "yield return" (generators), deferred execution is emulated using a `JsonhResultEnumerable` type. The type contains the finished results, but moves to the correct indexes in the source string as the enumerable is iterated.
