@tool
class_name JsonhGdBenchmarks extends EditorScript

func _run() -> void:
	benchmark(1.0, true)
	benchmark(1.0, false)

func benchmark(duration:float, use_jsonh:bool)->void:
	const json:String = "{ \"hello\": \"world\", \"data\": [ 1, 2, 3 ] }"
	
	if use_jsonh:
		print("JSONH:")
	else:
		print("JSON:")
	
	var counter: int = 0
	var start_timestamp: int = Time.get_ticks_msec()
	while (Time.get_ticks_msec() - start_timestamp) < (duration * 1000):
		if use_jsonh:
			var _value: Variant = JsonhGd.JsonhReader.parse_element_from_string(json).value
		else:
			var _value: Variant = JSON.parse_string(json)
		counter += 1
	print(Time.get_ticks_msec() - start_timestamp, "ms")
	print(counter, " times")
