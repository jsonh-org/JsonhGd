@tool
class_name JsonhGdTests extends EditorScript

func _run() -> void:
	#for method: Dictionary in get_method_list():
		#var method_name: String = method.name
		#if method_name.ends_with("Test"):
			#print(str("Running '", method_name, "'"))
			#call(method_name)
	#print("All tests finished")
	
	BasicObjectTest()
	NestableBlockCommentTest()
	FindPropertyValueTest()

# 
# Read Tests
# 

static func BasicObjectTest() -> void:
	var jsonh: String = """
{
	"a": "b"
}
"""
	var reader: JsonhGd.JsonhReader = JsonhGd.JsonhReader.new(jsonh)
	var tokens: Array[JsonhGd.JsonhResult] = reader.read_element().to_array()

	for token in tokens:
		assert(not token.is_error)
	assert(tokens[0].value().json_type == JsonhGd.JsonTokenType.START_OBJECT)
	assert(tokens[1].value().json_type == JsonhGd.JsonTokenType.PROPERTY_NAME)
	assert(tokens[1].value().value == "a")
	assert(tokens[2].value().json_type == JsonhGd.JsonTokenType.STRING)
	assert(tokens[2].value().value == "b")
	assert(tokens[3].value().json_type == JsonhGd.JsonTokenType.END_OBJECT)

static func NestableBlockCommentTest() -> void:
	var jsonh: String = """
/* */
/=* *=/
/==*/=**=/*==/
/=*/==**==/*=/
0
"""
	var reader: JsonhGd.JsonhReader = JsonhGd.JsonhReader.new(jsonh)
	var tokens: Array[JsonhGd.JsonhResult] = reader.read_element().to_array()

	for token in tokens:
		print(token.value())
		assert(not token.is_error)
	assert(tokens[0].value().json_type == JsonhGd.JsonTokenType.COMMENT)
	assert(tokens[0].value().value == " ")
	assert(tokens[1].value().json_type == JsonhGd.JsonTokenType.COMMENT)
	assert(tokens[1].value().value == " ")
	assert(tokens[2].value().json_type == JsonhGd.JsonTokenType.COMMENT)
	assert(tokens[2].value().value == "/=**=/")
	assert(tokens[3].value().json_type == JsonhGd.JsonTokenType.COMMENT)
	assert(tokens[3].value().value == "/==**==/")
	assert(tokens[4].value().json_type == JsonhGd.JsonTokenType.NUMBER)
	assert(tokens[4].value().value == "0")

static func FindPropertyValueTest() -> void:
	var jsonh: String = """
// Original position
{
	"a": "1",
	"b": {
		"c": "2"
	},
	"c":/* Final position */ "3"
}
"""
	var reader: JsonhGd.JsonhReader = JsonhGd.JsonhReader.new(jsonh)

	assert(reader.find_property_value("c"))
	assert(reader.parse_element().value() == "3")

# 
# Parse Tests
# 

static func EscapeSequenceTest() -> void:
	var jsonh: String = """
"\\U0001F47D and \\uD83D\\uDC7D"
"""
	var element: String = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == "👽 and 👽")

static func QuotelessEscapeSequenceTest() -> void:
	var jsonh: String = """
\\U0001F47D and \\uD83D\\uDC7D
"""
	var element: String = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == "👽 and 👽")

static func MultiQuotedStringTest() -> void:
	var jsonh: String = '''
""""
Hello! Here's a quote: ". Now a double quote: "". And a triple quote! """. Escape: \\\\\\U0001F47D.
""""
'''
	var element: String = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == " Hello! Here's a quote: \". Now a double quote: \"\". And a triple quote! \"\"\". Escape: \\👽.")

static func ArrayTest() -> void:
	var jsonh: String = '''
[
	1, 2,
	3
	4 5, 6
]
'''
	var element: Array = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(len(element) == 5)
	assert(element[0] == 1)
	assert(element[1] == 2)
	assert(element[2] == 3)
	assert(element[3] == "4 5")
	assert(element[4] == 6)

static func NumberParserTest() -> void:
	assert(int(JsonhGd.JsonhNumberParser.parse("1.2e3.4").value() as float) == 3014)

static func BracelessObjectTest() -> void:
	var jsonh: String = """
a: b
c : d
"""
	var element: Dictionary[String, String] = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(len(element) == 2)
	assert(element["a"] == "b")
	assert(element["c"] == "d")

static func CommentTest() -> void:
	var jsonh: String = """
[
	1 # hash comment
	    2 // line comment
	    3 /* block comment */, 4
]
"""
	var element: Array[int] = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(len(element) == 4)
	assert(element[0] == 1)
	assert(element[1] == 2)
	assert(element[2] == 3)
	assert(element[3] == 4)

static func VerbatimStringTest() -> void:
	var jsonh: String = """
{
	a\\\\: b\\\\
	@c\\\\: @d\\\\
	@e\\\\: f\\\\
}
"""
	var element: Dictionary[String, String] = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(len(element) == 3)
	assert(element["a\\"] == "b\\")
	assert(element["c\\\\"] == "d\\\\")
	assert(element["e\\\\"] == "f\\")

	var element2: Dictionary[String, String] = JsonhGd.JsonhReader.parse_element_from_string(jsonh, JsonhGd.JsonhReaderOptions.new(
		JsonhGd.JsonhVersion.V1,
	)).value()
	assert(len(element2) == 3)
	assert(element2["a\\"] == "b\\")
	assert(element2["@c\\"] == "@d\\")
	assert(element2["@e\\"] == "f\\")

	var jsonh2: String = """
@"a\\\\": @'''b\\\\'''
"""
	var element3: Dictionary[String, String] = JsonhGd.JsonhReader.parse_element_from_string(jsonh2).value()

	assert(len(element3) == 1)
	assert(element3["a\\\\"] == "b\\\\")

static func ParseSingleElementTest() -> void:
	var jsonh: String = """
1
2
"""
	var element: int = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == 1)

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh, JsonhGd.JsonhReaderOptions.new(
		JsonhGd.JsonhVersion.LATEST,
		true,
	)).is_error)

	var jsonh2: String = """
1


"""

	assert(not JsonhGd.JsonhReader.parse_element_from_string(jsonh2, JsonhGd.JsonhReaderOptions.new(
		JsonhGd.JsonhVersion.LATEST,
		true,
	)).is_error)

static func ParseJsonTest() -> void:
	var jsonh: String = """
{
	// Hello /* test */ world
	a: 'b'
	"c": '''私'''
	x: [a,b,c]
	y: {}
	z: 0.05e1
}
"""

	var reader: JsonhGd.JsonhReader = JsonhGd.JsonhReader.new(jsonh)
	assert(reader.parse_json().value() == '{"a":"b","c":"私","x":["a","b","c"],"y":{},"z":0.5}')

	var reader2: JsonhGd.JsonhReader = JsonhGd.JsonhReader.new(jsonh)
	assert(reader2.parse_json(true).value() == '{/* Hello / * test * / world*/"a":"b","c":"私","x":["a","b","c"],"y":{},"z":0.5}')

	var reader3: JsonhGd.JsonhReader = JsonhGd.JsonhReader.new(jsonh)
	assert(reader3.parse_json(false, "  ").value() == '''{
	"a": "b",
	"c": "私",
	"x": [
		"a",
		"b",
		"c"
	],
	"y": {},
	"z": 0.5
}''')

	var reader4: JsonhGd.JsonhReader = JsonhGd.JsonhReader.new(jsonh)
	assert(reader4.parse_json(true, "  ").value() == '''{
	/* Hello / * test * / world*/
	"a": "b",
	"c": "私",
	"x": [
		"a",
		"b",
		"c"
	],
	"y": {},
	"z": 0.5
}''')

	var jsonh2: String = '''
1
2
'''
	
	var reader5: JsonhGd.JsonhReader = JsonhGd.JsonhReader.new(jsonh2, JsonhGd.JsonhReaderOptions.new(
		JsonhGd.JsonhVersion.LATEST,
		false,
	))
	assert(reader5.parse_json().value() == "1")

	var reader6: JsonhGd.JsonhReader = JsonhGd.JsonhReader.new(jsonh2, JsonhGd.JsonhReaderOptions.new(
		JsonhGd.JsonhVersion.LATEST,
		true,
	))
	assert(reader6.parse_json().is_error)

	var jsonh3: String = '''
a: /*b*/ c
'''

	var reader7: JsonhGd.JsonhReader = JsonhGd.JsonhReader.new(jsonh3, JsonhGd.JsonhReaderOptions.new(
		JsonhGd.JsonhVersion.LATEST, false,
	))
	assert(reader7.parse_json().value() == "{\"a\":\"c\"}")

# 
# Edge Case Tests
# 

static func QuotelessStringStartingWithKeywordTest() -> void:
	var jsonh: String = """
[nulla, null b, null, @null]
"""
	var element: Array[Variant] = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(len(element) == 4)
	assert(element[0] == "nulla")
	assert(element[1] == "null b")
	assert(element[2] == null)
	assert(element[3] == "null")

static func BracelessObjectWithInvalidValueTest() -> void:
	var jsonh: String = """
a: {
"""
	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).is_error)

static func NestedBracelessObjectTest() -> void:
	var jsonh: String = """
[
	a: b
	c: d
]
"""
	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).is_error)

static func QuotelessStringsLeadingTrailingWhitespaceTest() -> void:
	var jsonh: String = """
[
	a b  , 
]
"""
	var element: Array[String] = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(len(element) == 1)
	assert(element[0] == "a b")

static func SpaceInQuotelessPropertyNameTest() -> void:
	var jsonh: String = """
{
	a b: c d
}
"""
	var element: Dictionary[String, String] = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(len(element) == 1)
	assert(element["a b"] == "c d")

static func QuotelessStringsEscapeTest() -> void:
	var jsonh: String = """
a: \\"5
b: \\\\z
c: 5 \\\\
"""
	var element: Dictionary[String, String] = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(len(element) == 3)
	assert(element["a"] == "\"5")
	assert(element["b"] == "\\z")
	assert(element["c"] == "5 \\")

static func MultiQuotedStringsNoLastNewlineWhitespaceTest() -> void:
	var jsonh: String = '''
"""
  hello world  """
'''
	var element: String = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == "\n  hello world  ")

static func MultiQuotedStringsNoFirstWhitespaceNewlineTest() -> void:
	var jsonh: String = '''
"""  hello world
  """
'''
	var element: String = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == "  hello world\n  ")

static func QuotelessStringsEscapedLeadingTrailingWhitespaceTest() -> void:
	var jsonh: String = """
\\nZ\\ \\r
"""
	var element: String = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == "Z")

static func HexNumberWithETest() -> void:
	var jsonh: String = """
0x5e3
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).value() == 0x5e3)

	var jsonh2: String = """
0x5e+3
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh2).value() == 5000)

static func NumberWithRepeatedUnderscoresTest() -> void:
	var jsonh: String = """
100__000
"""
	var element: int = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == 100_000)

static func NumberWithUnderscoreAfterBaseSpecifierTest() -> void:
	var jsonh: String = """
0b_100
"""
	var element: int = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == 0b100)

static func NegativeNumberWithBaseSpecifierTest() -> void:
	var jsonh: String = """
-0x5
"""
	var element: int = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == -0x5)

static func NumberDotTest() -> void:
	var jsonh: String = """
.
"""
	assert(typeof(JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()) == TYPE_STRING)
	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).value() == ".")

	var jsonh2: String = """
-.
"""
	assert(typeof(JsonhGd.JsonhReader.parse_element_from_string(jsonh2).value()) == TYPE_STRING)
	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh2).value() == "-.")

static func DuplicatePropertyNameTest() -> void:
	var jsonh: String = """
{
	a: 1,
	c: 2,
	a: 3,
}
"""
	var element: Dictionary[String, int] = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == {
		"c": 2,
		"a": 3,
	})

static func EmptyNumberTest() -> void:
	var jsonh: String = """
0e
"""
	var element: String = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(typeof(element) == TYPE_STRING)
	assert(element == "0e")

static func LeadingZeroWithExponentTest() -> void:
	var jsonh: String = """
[0e4, 0xe, 0xEe+2]
"""
	var element: Array[int] = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(element == [0e4, 0xe, 1400])

	var jsonh2: String = """
[e+2, 0xe+2, 0oe+2, 0be+2]
"""
	var element2: Array[String] = JsonhGd.JsonhReader.parse_element_from_string(jsonh2).value()

	assert(element2 == ["e+2", "0xe+2", "0oe+2", "0be+2"])

	var jsonh3: String = """
[0x0e+, 0b0e+_1]
"""
	var element3: Array[String] = JsonhGd.JsonhReader.parse_element_from_string(jsonh3).value()

	assert(element3 == ["0x0e+", "0b0e+_1"])

static func ErrorInBracelessPropertyNameTest() -> void:
	var jsonh: String = """
a /
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).is_error)

static func FirstPropertyNameInBracelessObjectTest() -> void:
	var jsonh: String = """
a: b
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).value() == { "a": "b" })

	var jsonh2: String = """
0: b
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh2).value() == { "0": "b" })

	var jsonh3: String = """
true: b
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh3).value() == { "true": "b" })

static func FractionLeadingZeroesTest() -> void:
	var jsonh: String = """
0.04
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).value() == 0.04)

static func BigNumbersTest() -> void:
	var jsonh: String = """
[
	3.5,
	1e99999,
	999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
]
"""
	var element: Array[float] = JsonhGd.JsonhReader.parse_element_from_string(jsonh).value()

	assert(len(element) == 3)
	assert(element[0] == 3.5)
	assert(element[1] == INF)
	assert(element[2] == INF)

static func MaxDepthTest() -> void:
	var jsonh: String = """
{
	a: {
		b: {
		    c: ""
		}
		d: {
		}
	}
}
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh, JsonhGd.JsonhReaderOptions.new(
		JsonhGd.JsonhVersion.LATEST,
		false,
		2,
	)).is_error)

	assert(not JsonhGd.JsonhReader.parse_element_from_string(jsonh, JsonhGd.JsonhReaderOptions.new(
		JsonhGd.JsonhVersion.LATEST,
		false,
		3,
	)).is_error)

static func UnderscoreAfterLeadingZeroTest() -> void:
	var jsonh: String = """
0_0
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).value() == 0)

static func UnderscoreBesideDotTest() -> void:
	var jsonh: String = """
[0_.0, 0._0]
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).value() == ["0_.0", "0._0"])

static func MultiQuotedStringWithNonAsciiIndentsTest() -> void:
	var jsonh: String = '''
　
"""
　　 a
　　"""
'''

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).value() == " a")

static func JoinCrLfInMultiQuotedStringTest() -> void:
	var jsonh: String = " ''' \\r\\nHello\r\n ''' "

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).value() == "Hello")

static func MassiveNumbersTest() -> void:
	var jsonh: String = """
[
	0x999_999_999_999_999_999_999_999,
	0x999_999_999_999_999_999_999_999.0,
]
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).value() == [
		47_536_897_508_558_602_556_126_370_201.0,
		47_536_897_508_558_602_556_126_370_201.0,
	])

static func FractionalHexadecimalNumbersTest() -> void:
	var jsonh: String = """
[0xA.A, 0xA.A1]
"""

	assert(JsonhGd.JsonhReader.parse_element_from_string(jsonh).value() == [10.625, 10.62890625])
