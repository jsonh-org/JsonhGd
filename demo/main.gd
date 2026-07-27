extends Node

func _ready() -> void:
	var jsonh: String = """
{
    this is: awesome
}
"""
	var element: Variant = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()
	print(element)
