extends "res://tests/test_case.gd"
## Tests for the LZW and RLEW decompressors with small hand-made inputs.

## "ABABABAAAAAAA" compressed with Keen 1's LZW variant: a 6-byte header
## (size 13, max code width 12) followed by the 9-bit codes
## 65 66 258 260 65 262 263 257. Code 260 is used before it is complete,
## which exercises the special "KwKwK" case.
const LZW_SAMPLE: PackedByteArray = [13, 0, 0, 0, 12, 0, 32, 144, 160, 80, 66, 12, 26, 15, 1]


func test_lzw_restores_original_bytes() -> void:
	var output := LzwDecompressor.decompress(LZW_SAMPLE)
	assert_equal(output.get_string_from_ascii(), "ABABABAAAAAAA", "decompressed text")


func test_lzw_rejects_truncated_data() -> void:
	var output := LzwDecompressor.decompress(LZW_SAMPLE.slice(0, 8))
	assert_true(output.is_empty(), "truncated data should give an empty result")


func test_rlew_copies_plain_words() -> void:
	# Size 4 bytes, then the words 0x1234 and 0x0001.
	var data := PackedByteArray([4, 0, 0, 0, 0x34, 0x12, 0x01, 0x00])
	assert_equal(RlewDecompressor.decompress(data), PackedInt32Array([0x1234, 1]), "words")


func test_rlew_expands_repeat_blocks() -> void:
	# Size 8 bytes, then 0x0007, and "repeat 0x0009 three times".
	var data := PackedByteArray([8, 0, 0, 0, 0x07, 0, 0xFE, 0xFE, 3, 0, 0x09, 0])
	assert_equal(RlewDecompressor.decompress(data), PackedInt32Array([7, 9, 9, 9]), "words")
