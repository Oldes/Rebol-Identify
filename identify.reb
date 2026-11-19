Rebol [
	title:  "File type identifier"
	name:    identify
	type:    module
	version: 1.1.0
	date:    19-Nov-2026
	author:  @oldes
	license: MIT
	exports: [identify]
	purpose: {Identify file type of file or binary data}
	home:    https://github.com/Oldes/Rebol-Identify/
	;;https://github.com/sindresorhus/file-type
	;;https://github.com/h2non/filetype
	;;https://pypi.org/project/filetype/
	;;https://docs.fileformat.com/
	;;https://www.iana.org/assignments/media-types/media-types.xhtml
]

identify: func [
	"Identifies file types using their magic numbers."
	file [file! url! binary!]
	;return: [none! file!] ;; this specification is available since version 3.18.5!
	/local src size result
][
	unless binary? src: file [file: read/part/binary file 512]
	;; skip an ID3v2 tag (when complete in the buffer) and identify the content after it
	if all [
		size: id3v2-size? file
		size < length? file
		result: identify skip file size
	][	return result ]
	result: match-head file
	;; ZIP based formats are resolved using the central directory (only for local files)
	if all [result == %zip  file? src][
		result: any [zip-type? src  result]
	]
	result
]

match-head: func [
	"Returns file type matching the head of the binary using the TYPES rules"
	bin [binary!]
][
	foreach [type rule] types [
		if type: parse bin [rule to end (return type)][
			return type
		]
	]
	none
]

types: make map! [
	%mid  [
		"MThd" |
		"SMF2CLIP" ; https://www.iana.org/assignments/media-types/audio/midi-clip
	]
	%m4a  ["M4A " | 4 skip "ftypM4A"]
	;; Ogg: codec identification header of the first packet is at offset 28
	%opus ["OggS" 24 skip "OpusHead"]
	%ogv  ["OggS" 24 skip #"^(80)" "theora"]
	%ogm  ["OggS" 24 skip #"^(01)" "video^@"]
	%spx  ["OggS" 24 skip "Speex   "]
	%oga  ["OggS" 24 skip #"^(7F)" "FLAC"]
	%ogg  ["OggS" 24 skip #"^(01)" "vorbis"]
	%ogx   "OggS" ;= application/ogg (other)
	%flac  "fLaC"
	%wav  ["RIFF" 4 skip "WAVE"]
	%amr   "#!AMR" ;= audio/amr ("#!AMR^/" or "#!AMR-WB^/")
	%aac  [#"^(FF)" #"^(F1)" | #"^(FF)" #"^(F9)"]
	%aif  ["FORM" 4 skip "AIF" [#"F" | #"C"]]
	%jls   #{FFD8FFF7} ;; JPG7/SOF55, indicating a ISO/IEC 14495 / JPEG-LS file
	%jpg   #{FFD8FF}
	%jpx  [#{0000000C} 12 skip "ftypjpx "]
	%jp2  [#{0000000C} 12 skip "ftypjp2 "]
	%jpm  [#{0000000C} 12 skip "ftypjpm "]
	%mj2  [#{0000000C} 12 skip "ftypmjp2"]
	%jxl  [#"^(FF)" #"^(0A)" | #{0000000C} "JXL ^M" skip #"^(87)" #"^(0A)"]
	%apng [#{89504e470d0a1a0a} to "acTL"] ;; simplified!
	%png  [#"^(89)" "PNG"]
	%gif   "GIF"
	%webp ["RIFF" 4 skip "WEBPVP"]
	%cr2  [["II*^@" | "MM^@*"] 4 skip "CR"]
	%tiff [["II*^@" | "MM^@*"] 4 skip not "CR" | "II+^@" | "MM^@+"] ;; TIFF | BigTIFF
	%bmp   "BM"
	%jxr   #{4949BC}
	%psd   ["8BPS" #"^(00)" #"^(01)"]
	%psb   ["8BPS" #"^(00)" #"^(02)"] ;= Photoshop large document
	%heic [
		isobmf
		[
			heic_brand |
			[
				"mif1" | "msf1"
			] 4 skip [heic_brand | 4 skip heic_brand | 8 skip heic_brand | 12 skip heic_brand]
		]
	]
	%dcm  [128 skip "DICM"]
	%dwg  "AC10"
	%xcf  "gimp xcf " ;= image/x-xcf ("gimp xcf file" or "gimp xcf v...")
	%avif [
		isobmf
		[
			"avif" | "avis" |
			[
				"mif1" | "msf1"
			] 4 skip ["avif" | 4 skip "avif" | 8 skip "avif" | 12 skip "avif"]
		]
	]
	%qoi   "qoif"
	%dds   "DDS "
	%rpm   #{edabeedb}
	%epub [#{504B0304} 26 skip "mimetypeapplication/epub+zip"]
	;; OpenDocument: uncompressed "mimetype" entry first (templates before base types!)
	%ott  [odf_mime "text-template"]
	%odm  [odf_mime "text-master"]
	%odt  [odf_mime "text"]
	%ots  [odf_mime "spreadsheet-template"]
	%ods  [odf_mime "spreadsheet"]
	%otp  [odf_mime "presentation-template"]
	%odp  [odf_mime "presentation"]
	%otg  [odf_mime "graphics-template"]
	%odg  [odf_mime "graphics"]
	%odf  [odf_mime "formula"]
	%odc  [odf_mime "chart"]
	%odi  [odf_mime "image"]
	%zip  ["PK" [#"^(03)" | #"^(05)" | #"^(07)"] [#"^(04)" | #"^(06)" | #"^(08)"] return (%zip)]
	%rar  ["Rar!" #"^(1A)" #"^(07)" [#"^(00)" | #"^(01)"]]
	%gz   #{1F8B08}
	%bz2   "BZh"
	%7z   #{377ABCAF271C}
	%pdf  [opt #{EFBBBF} "%PDF"]
	%exe   "MZ"
	%swf  ["FWS" | "CWS" | "ZWS"]
	%rtf   "{\rtf" ;= application/rtf
	%nes   ["NES" #"^(1A)"]   ;= application/x-nintendo-nes-rom
	%crx   "Cr24"   ;= application/x-google-chrome-extension
	%cab  ["MSCF" | "ISc("] ;= application/vnd.ms-cab-compressed
	;%eot [8 skip [#{020001} | #{010000} | #{020002}] 23 skip #{4C50}] ;= application/octet-stream
	%eps  [
		#{C5D0D3C6} |
		"%!PS-Adobe-" 3 skip " EPSF-" ;= "%!PS-Adobe-XXX EPSF-XXX"
	] 
	%ps     "%!"
	%xz     [#"^(FD)" "7zXZ" #"^(00)"]
	%sqlite "SQLi"
	%deb    "!<arch>^/debian-binary"
	%ar     "!<arch>"
	%z     [#"^(1F)" #"^(A0)" | #"^(1F)" #"^(9D)"]
	%lzop   #{894C5A4F000D0A1A}
	%lz     "LZIP"
	%elf   [#"^(7F)" "ELF" 48 skip]
	%lz4    #{04224D18}
	%br     #{ceb2cf81}
	%zst   [[#"^(22)" | #"^(23)" | #"^(24)" | #"^(25)" | #"^(26)" | #"^(27)" | #"^(28)"] #{B52FFD}] ;! only Zstandard frames

	
	%m4v   [isobmf "M4V"] ;; "M4V ", "M4VH", "M4VP"
	%mkv   [#{1A45DFA3} [to #{428288 6D6174726F736B61} | to #{428289 6D6174726F736B6100}]] ;; DocType may be null-terminated
	%webm  [#{1A45DFA3} [to #{428284 7765626D} | to #{428285 7765626D00}]]
	;; ISO-BMFF rules checking a specific major brand must precede %mp4,
	;; which also matches by compatible brands (isom/mp41/mp42)
	%mov   [
		isobmf "qt  "
		;; QuickTime without ftyp box: moov, mdat, wide, free, skip or pnot atom first
		| 4 skip ["moov" | "mdat" | "wide" | "free" | "skip" | "pnot"]
	]
	%3g2   [isobmf "3g2" ]
	%3gp   [isobmf "3gp" ]
	%f4a   [isobmf "F4A "]
	%f4b   [isobmf "F4B "]
	%f4p   [isobmf "F4P "]
	%f4v   [isobmf "F4V "]
	%m4b   [isobmf "M4B "]
	%m4p   [isobmf "M4P "]
	%cr3   [isobmf "crx "] ;= image/x-canon-cr3
	%mp4   [isobmf [mp4_brand | 8 skip [mp4_brand | 4 skip mp4_brand | 8 skip mp4_brand] ]]
	%avi   ["RIFF" 4 skip "AVI "]
	%asf     #{3026B2758E66CF11A6D9}
	%flv    ["FLV" #"^(01)"]
	%mpg   [#{000001} mpg_ver]

	%wasm  [#"^(00)" "asm" skip 3 null]

	%tar   [257 skip "ustar" | pos: if (tar-checksum? pos)] ;; ustar | old v7 header without magic


	%ac3    [#"^(0B)" #"^(77)"]
	%cpio   [#"^(C7)" #"^(71)" | #"^(71)" #"^(C7)" | ["07070" [#"7" | #"1" | #"2"]]]
	%arj    [#"^(60)" #"^(EA)"]
	%mpc    ["MP+" | "MPCK"]
	%avro   ["Obj" #"^(01)"]                ;= application/avro
	%flif    "FLIF"                         ;= image/flif
	%icns    "icns"                         ;= image/icns
	%woff   ["wOFF" [#{00010000} | "OTTO"]] ;= font/woff
	%woff2  ["wOF2" [#{00010000} | "OTTO"]] ;= font/woff2
	%pcap   [#{D4C3B2A1} | #{A1B2C3D4}]     ;= application/vnd.tcpdump.pcap
	%dsf     "DSD "                         ;= audio/x-dsf
	%bpg    ["BPG" #"^(FB)"]                ;= image/bpg
	%wv      "wvpk"                         ;= audio/wavpack
	%ape     "MAC "                         ;= audio/ape
	%pst     "!BDN"                         ;= application/vnd.ms-outlook
	%parquet "PAR1"                         ;= application/x-parquet
	%ttc     "ttcf"                         ;= font/collection
	%macho  [                               ;= application/x-mach-binary
		   #{CFFAEDFE} | #{CEFAEDFE}        ;; 64/32-bit little-endian
		|  #{FEEDFACF} | #{FEEDFACE}        ;; 64/32-bit big-endian
		| [#{CAFEBABE} | #{CAFEBABF}] #{000000} fat_count ;; universal (fat) binary; CAFEBABE is shared with Java class files!
	]
	%otf    "OTTO^@" ;= font/otf
	%it     "IMPM"   ;= audio/x-it
	%lzh  [ ;= application/x-lzh-compressed
		2 skip "-l" [
			  #"h" [#"0" | #"1" | #"2" | #"3" | #"4" | #"5" | #"6" | #"7" | #"d"]
			| #"z" [#"s" | #"4" | #"5"]
		]
	]
	%chm   "ITSF"   ;= application/vnd.ms-htmlhelp
	%class #{CAFEBABE}   ;= application/java-vm
	%rm    ".RMF"   ;= application/vnd.rn-realmedia
	%drc   "DRACO" ;= application/vnd.google.draco
	%xml [
		"<?xml " |
		#{EFBBBF} "<?xml " |
		#{FFFE 3C003F0078006D006C00} |
		#{FEFF 003C003F0078006D006C}
	]
	%stl    "solid " ;= model/stl
	%blend  "BLENDER"
	%vtt   [opt #{EFBBBF} "WEBVTT" [cr | lf | tab | sp | null | end]] ;= text/vtt
	%arrow  "ARROW1^@^@" ;= application/x-apache-arrow
	%glb   ["glTF" #{02000000}] ;= model/gltf-binary
	%orf   ["IIRO" #{0800000018}] ;= image/x-olympus-orf
	%qcp   ["RIFF" 4 skip "QLCM"]
	%rw2   ["IIU^@" #{1800000088E774D8}]
	%ktx   [#"^(AB)" "KTX 11" #{BB0D0A1A0A}]
	%mie   [[#{7E1004} | #{7E1804}] skip "0MIE"]
	%shp   [2 skip #"^(27)" #"^(0A)" 10 null]
	%j2c   #{FF4FFF51}
	%cfb   #{D0CF11E0A1B11AE1}
	%icc   [36 skip "acsp"]
	%ace   [7 skip "**ACE**"]
	%vcf    "BEGIN:VCARD"
	%ics    "BEGIN:VCALENDAR"
	%raf    "FUJIFILMCCD-RAW"
	%xm     "Extended Module:"
	%voc    "Creative Voice File"
	%asar  [
		#{04000000}
		12 skip "{^"files^":"
		;; code bellow would work only if the buffer would be large enough!
		;; 8 skip pos: if (map? try [decode 'json binary/read skip b 12 'ui32lebytes])
	]
	%mxf   #{060E2B34020501010D0102010102}
	%s3m   [44 skip "SCRM"]
	%mts   [
		;Raw MPEG-2 transport stream (188-byte packets)
		  #"^(47)" 187 skip #"^(47)"
		|
		;Blu-ray Disc Audio-Video (BDAV) MPEG-2 transport stream has 4-byte TP_extra_header before each 188-byte packet
		  4 skip #"^(47)" 191 skip #"^(47)"
	]
	%mobi   [60 skip "BOOKMOBI"]
	%lnk    #{4C0000000114020000000000C000000000000046}
	%alias  ["book" #{00000000} "mark" #{00000000}]
	%fbx    ["Kaydara FBX Binary  ^@" #"^(1A)"]
	%eot    [8 skip [#{000001} | #{010002} | #{020002}] 23 skip "LP"]
	%indd   #{0606EDF5D81D46E5BD31EFE7FE74B71D}
	%pgp     "-----BEGIN PGP MESSAGE-----"
	%skp    #{FFFE FF0E53006B0065007400630068005500700020004D006F00640065006C00}
	%mp3    ["ID3" | mpg_sync if (0#02 == (pos and 0#06))]
	%mp2    [mpg_sync if (0#04 == (pos and 0#06))]
	%mp1    [mpg_sync if (0#06 == (pos and 0#06))]

	;- Documents and data
	%djvu    ["AT&TFORM" 4 skip ["DJVU" | "DJVM"]] ;= image/vnd.djvu
	%plist    "bplist"                    ;= application/x-bplist
	%pem      "-----BEGIN "               ;= application/x-pem-file (must follow %pgp!)
	%mdb     [4 skip "Standard Jet DB"]   ;= application/x-msaccess
	%accdb   [4 skip "Standard ACE DB"]   ;= application/x-msaccess
	%torrent ["d8:announce" | "d13:announce-list"] ;= application/x-bittorrent
	;- Audio
	%caf     ["caff" #"^(00)" #"^(01)"]   ;= audio/x-caf (version 1)
	%au       ".snd"                      ;= audio/basic
	%dff     ["FRM8" 8 skip "DSD "]       ;= audio/x-dff
	%tta      "TTA1"                      ;= audio/x-tta
	;- Images
	%exr      #{762F3101}                 ;= image/x-exr
	%hdr     ["#?" ["RADIANCE" | "RGBE"]] ;= image/vnd.radiance
	%pbm     [#"P" [#"1" | #"4"] pnm_ws]  ;= image/x-portable-bitmap
	%pgm     [#"P" [#"2" | #"5"] pnm_ws]  ;= image/x-portable-graymap
	%ppm     [#"P" [#"3" | #"6"] pnm_ws]  ;= image/x-portable-pixmap
	%pam     [#"P" #"7" pnm_ws]           ;= image/x-portable-arbitrarymap
	%mng      #{8A4D4E470D0A1A0A}         ;= video/x-mng
	%jng      #{8B4A4E470D0A1A0A}         ;= image/x-jng
	%ktx2    [#"^(AB)" "KTX 20" #{BB0D0A1A0A}] ;= image/ktx2
	;- Archives and disk images
	%xar      "xar!"                      ;= application/x-xar
	%squashfs ["hsqs" | "sqsh"]           ;= application/x-squashfs
	%qcow2    ["QFI" #"^(FB)"]            ;= application/x-qemu-disk
	%vmdk      "KDMV"                     ;= application/x-vmdk
	%vhdx      "vhdxfile"                 ;= application/x-vhdx
	%vhd       "conectix"                 ;= application/x-vhd (dynamic disks only)
	;- Code
	%dex     ["dex^/" 3 skip null]        ;= application/x-android-dex ("dex^/035^@")
	%luac    [#"^(1B)" "Lua"]             ;= application/x-lua-bytecode
	;- 3D
	%ply     ["ply" [lf | cr]]            ;= model/ply
	%usdc     "PXR-USDC"                  ;= model/vnd.usd

	;; imprecise...
	%ico     #{00000100}
	%cur     #{00000200}
	%ttf     #{0001000000}
]

mimes: [
	"font/ttf" %ttf
	"text/vcard" %vcf
	"text/calendar" %ics
	"audio/midi"  %mid %midi
	"audio/qcelp" %qcp
	"audio/x-xm"  %xm
	"audio/x-voc" %voc
	"audio/x-s3m" %s3m
	"audio/x-musepack" %mpc
	"image/ktx" %ktx
	"image/j2c" %j2c
	"image/x-panasonic-rw2" %rw2
	"image/x-fujifilm-raf" %raf
	"video/mp2t" %mts
	"video/3gpp2" %3g2
	"application/mxf" %mxf
	"application/pgp-encrypted" %pgp
	"application/x-mie" %mie
	"application/x-esri-shape" %shp
	"application/x-cfb" %cfb ;= Microsoft Compound File Binary File (MS-CFB) Format
	"application/vnd.iccprofile" %icc
	"application/vnd.ms-fontobject" %eot
	"application/vnd.sketchup.skp" %skp
	"application/x-ace-compressed" %ace
	"application/x-asar" %asar
	"application/x-mobipocket-ebook" %mobi
	"application/x.ms.shortcut" %lnk
	"application/x.apple.alias" %alias
	"application/x.autodesk.fbx" %fbx
	"application/x-indesign" %indd
	"application/x-cpio" %cpio
	"application/x-blender" %blend %blender
	"public.aiff-audio" %aif %aiff


]
mpg_ver: charset [#"^(b0)" - #"^(bf)"]
mpg_sync: [#"^(FF)" set pos: skip if (0#E0 == (pos and 0#E0))]
mp4_brand: ["mp42" | "mp41" | "isom"]
heic_brand: ["heic" | "heix" | "hevc" | "hevx"]
isobmf: [4 skip "ftyp"]
odf_mime: [#{504B0304} 26 skip "mimetypeapplication/vnd.oasis.opendocument."]
pos: none
id3v2-size?: function [
	"Returns total size of the ID3v2 tag at the head of the binary, or none"
	bin [binary!]
][
	all [
		10 <= length? bin
		did find/match bin #{494433}
		b: skip bin 6
		zero? 128 and (b/1 or b/2 or b/3 or b/4) ;; syncsafe integer
		10                                       ;; header
		+ (b/1 * 2097152) + (b/2 * 16384) + (b/3 * 128) + b/4
		+ either zero? 16 and bin/6 [0][10]      ;; footer present
	]
]

has-prefix?: func [
	"Returns true if any of the strings starts with the prefix"
	strings [block!] prefix [string!]
][
	foreach str strings [if find/match str prefix [return true]]
	false
]

ooxml-types: [
	;; main part content types in [Content_Types].xml (more specific first)
	"ms-word.template.macroEnabledTemplate.main+xml"        %dotm
	"ms-word.document.macroEnabled.main+xml"                %docm
	"wordprocessingml.template.main+xml"                    %dotx
	"wordprocessingml.document.main+xml"                    %docx
	"ms-excel.template.macroEnabled.main+xml"               %xltm
	"ms-excel.sheet.macroEnabled.main+xml"                  %xlsm
	"spreadsheetml.template.main+xml"                       %xltx
	"spreadsheetml.sheet.main+xml"                          %xlsx
	"ms-powerpoint.template.macroEnabled.main+xml"          %potm
	"ms-powerpoint.presentation.macroEnabled.main+xml"      %pptm
	"presentationml.template.main+xml"                      %potx
	"presentationml.presentation.main+xml"                  %pptx
]

read-zip-entry: function [
	"Reads and decompresses a ZIP entry, or returns none"
	file   [file!]
	method [integer!] "0 = stored, 8 = deflate"
	csize  [integer!] "Compressed size"
	offset [integer!] "Offset of the local file header"
][
	attempt [
		lh: read/seek/part file offset 30
		unless find/match lh #{504B0304} [return none]
		binary/read lh [SKIP 26 nlen: UI16LE elen: UI16LE]
		data: read/seek/part file (offset + 30 + nlen + elen) csize
		switch method [
			0 [data]
			8 [decompress data 'deflate]
		]
	]
]

zip-type?: function [
	"Returns specific type of a ZIP based file using its central directory, or none"
	file [file!]
][
	unless all [size: size? file  size >= 22][return none]
	;; the end of central directory record is within the last 22 + 65535 bytes
	len: min size 65557
	unless all [
		bin: attempt [read/seek/part file size - len len]
		eocd: find/last bin #{504B0506}
		22 <= length? eocd
	][	return none ]
	binary/read eocd [SKIP 12 cd-size: UI32LE cd-offset: UI32LE]
	if any [cd-size = 0#FFFFFFFF  cd-offset = 0#FFFFFFFF][return none] ;; ZIP64
	unless cd: attempt [read/seek/part file cd-offset cd-size][return none]

	names: make block! 32
	content-types: none
	while [all [46 <= length? cd  find/match cd #{504B0102}]][
		binary/read cd [
			SKIP 10 method: UI16LE
			SKIP 8  csize:  UI32LE
			SKIP 4  nlen:   UI16LE elen: UI16LE clen: UI16LE
			SKIP 8  offset: UI32LE
		]
		append names name: to string! copy/part skip cd 46 nlen
		if name == "[Content_Types].xml" [
			content-types: reduce [method csize offset]
		]
		cd: skip cd 46 + nlen + elen + clen
	]

	case [
		find names "AndroidManifest.xml"   [%apk]
		find names "META-INF/mozilla.rsa"  [%xpi]
		find names "3D/3dmodel.model"      [%3mf]
		has-prefix? names "visio/"         [%vsdx]
		content-types [
			if xml: read-zip-entry file content-types/1 content-types/2 content-types/3 [
				xml: to string! xml
				foreach [ct type] ooxml-types [
					if find xml ct [return type]
				]
			]
			;; fallback when the content types are not available
			case [
				has-prefix? names "word/" [%docx]
				has-prefix? names "xl/"   [%xlsx]
				has-prefix? names "ppt/"  [%pptx]
			]
		]
		find names "META-INF/MANIFEST.MF"  [%jar]
	]
]

fat_count: charset [#"^(01)" - #"^(1F)"] ;; number of architectures (Java class has its version >= 45 here)
pnm_ws: charset " ^-^/^M"
tar_digit: charset [#"0" - #"7"]

tar-checksum?: function [
	"Returns true if the binary starts with a tar header with a valid checksum"
	hdr [binary!] "Needs at least 512 bytes"
][
	if any [512 > length? hdr  zero? hdr/1][return false]
	stored: 0
	unless parse copy/part skip hdr 148 8 [
		any #" "
		copy digits: some tar_digit (foreach d digits [stored: stored * 8 + d - 48])
		[null | #" "] to end
	][	return false ]
	sum: 256 ;; the checksum field itself is counted as 8 spaces
	foreach b copy/part hdr 148 [sum: sum + b]
	foreach b copy/part skip hdr 156 356 [sum: sum + b]
	stored == sum
]
