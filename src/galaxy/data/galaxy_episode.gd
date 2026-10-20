class_name GalaxyEpisode
extends RefCounted
## The numbers of one Galaxy episode that the shared readers in
## [code]src/galaxy/[/code] need: file names, where the headers were seen in
## the known versions, and the sizes of the parts of EGAGRAPH that no table
## gives. Keen 4 fills one in [Keen4Episode]; Keen 5 and 6 will fill their
## own, so no Galaxy class holds a number of one episode.

## The pieces of the program that the data files need (docs/keen4/file-formats.md).
enum Header { AUDIOHED, EGAHEAD, MAPHEAD, TILEINFO, AUDIODCT, EGADICT }

## The extension of the data files, without the dot ("CK4").
var extension := ""
## The names the program may have, the first that is present is read.
var executables: PackedStringArray = []
## The size of the program file on disk per version, used when the sign-on
## text gives no version.
var executable_sizes: Dictionary[String, int] = {}
## Where each [enum Header] was seen in the known versions (raw image
## offsets). Only tried first; used only when the content passes the check.
## TILEINFO needs none: it always follows MAPHEAD.
var known_offsets: Dictionary[Header, PackedInt32Array] = {}
## EGAGRAPH chunks that no table counts: fonts (right after the three
## tables), and at the end the misc chunks, the texts and the demos.
var font_count := 0
var misc_count := 0
var text_count := 0
var demo_count := 0
## How many maps have a name in the program (the level names and the
## "Keen enters ..." texts, one each).
var level_name_count := 0
## Where the level names were seen in the known versions.
var known_level_name_offsets: PackedInt32Array = []
## Runs of messages found by their shape: name -> the number of lines of
## each message in the run (a message is one record, lines end in a newline).
var message_shapes: Dictionary[String, PackedInt32Array] = {}
## Where those runs were seen in the known versions: name -> offsets.
var known_message_offsets: Dictionary[String, PackedInt32Array] = {}


## The data file [param base] with this episode's extension, such as
## "EGAGRAPH.CK4".
func file_name(base: String) -> String:
	return "%s.%s" % [base, extension]


## The name of the program in [param files], or "" when none is there.
func executable_in(files: GameFiles) -> String:
	for name in executables:
		if files.has_file(name):
			return name
	return ""
