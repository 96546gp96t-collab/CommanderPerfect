class_name DosExecutable
extends RefCounted
## Gives access to the program image of a DOS .EXE file, so that data tables
## can be read from it (for example the tile properties in KEEN1.EXE).
##
## Only data is read from the image; the program code is never interpreted.
##
## An EXE starts with an MZ header; the program image follows after
## [code]header paragraphs * 16[/code] bytes. KEEN1.EXE is packed with LZEXE
## 0.91, recognizable by the signature "LZ91" at offset 0x1C. Its image is
## then unpacked with [LzexeDecompressor] first. Relocations do not matter for
## reading data and are ignored.

const MZ_SIGNATURE := 0x5A4D  # "MZ"
const HEADER_PARAGRAPHS_OFFSET := 0x08
const PARAGRAPH_SIZE := 16
const HEADER_SIZE := 0x1C
const LZEXE_SIGNATURE_OFFSET := 0x1C
const LZEXE_091_SIGNATURE := "LZ91"
const LZEXE_090_SIGNATURE := "LZ09"


## Returns the unpacked program image, or an empty array when the file is not
## a supported EXE.
static func load_image(exe: PackedByteArray) -> PackedByteArray:
	if exe.size() < HEADER_SIZE or exe.decode_u16(0) != MZ_SIGNATURE:
		push_error("Not a DOS executable.")
		return PackedByteArray()

	var image_start := exe.decode_u16(HEADER_PARAGRAPHS_OFFSET) * PARAGRAPH_SIZE
	if image_start > exe.size():
		push_error("The executable ends inside its header.")
		return PackedByteArray()

	match _signature(exe):
		LZEXE_091_SIGNATURE:
			return LzexeDecompressor.decompress(exe.slice(image_start))
		LZEXE_090_SIGNATURE:
			push_error("Executables packed with LZEXE 0.90 are not supported.")
			return PackedByteArray()
	return exe.slice(image_start)


static func _signature(exe: PackedByteArray) -> String:
	if exe.size() < LZEXE_SIGNATURE_OFFSET + LZEXE_091_SIGNATURE.length():
		return ""
	var bytes := exe.slice(
		LZEXE_SIGNATURE_OFFSET, LZEXE_SIGNATURE_OFFSET + LZEXE_091_SIGNATURE.length()
	)
	return bytes.get_string_from_ascii()
