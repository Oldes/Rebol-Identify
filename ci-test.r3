Rebol [title: "Identify Test script"]

;; make sure that we load a fresh extension
try [system/modules/identify: none unset 'identify]

;; use current directory as a modules location
system/options/modules: what-dir

import identify
import mime-types ;https://src.rebol.tech/mezz/codec-mime-types.reb

failed: 0

;; old v7 tar header (no ustar magic) with a valid checksum, padded to 512 bytes
tar-v7: append/dup copy #{
	746573742E6A7067000000000000000000000000000000000000000000000000
	0000000000000000000000000000000000000000000000000000000000000000
	0000000000000000000000000000000000000000000000000000000000000000
	0000000030303030363434003030303037363400303030313034300030303030
	3030303433313000313232303435313536343400303036323735002030
} #{00} 355
;; the same header with a corrupted checksum
tar-bad: head change skip copy tar-v7 148 #{31}

foreach [type file] compose [
	%avif %fixtures/sample.avif
	%dds  %fixtures/sample.dds
;	%doc  %fixtures/sample.doc
;	%docx %fixtures/sample.docx
	%gif  %fixtures/sample.gif
	%heic %fixtures/sample.heic
	%jp2  %fixtures/sample.jp2
	%jpg  %fixtures/sample.jpg
	%jxl  %fixtures/sample.jxl
	%m4a  %fixtures/sample.m4a
	%mov  %fixtures/sample.mov
	%mp4  %fixtures/sample.mp4
;	%odp  %fixtures/sample.odp
;	%ods  %fixtures/sample.ods
;	%odt  %fixtures/sample.odt
	%pdf  %fixtures/sample.pdf
	%png  %fixtures/sample.png
;	%ppt  %fixtures/sample.ppt
;	%pptx %fixtures/sample.pptx
	%tar  %fixtures/sample.tar
	%tiff %fixtures/sample.tif
	%wav  %fixtures/sample.wav
	%webp %fixtures/sample.webp
;	%xls  %fixtures/sample.xls
;	%xlsx %fixtures/sample.xlsx
	%zip  %fixtures/sample.zip
	%zst  %fixtures/sample.zst

	%jpx  #{0000000C6A5020200D0A870A00000000667479706A707820}
	%cr2  #{49492A00 00000000 4352}
	%tiff #{49492A00 00000000 FFFF}
	%mp3  #{FFFAAA}
	%epub #{504B0304140000080000FC687D5A6F61AB2C1400000014000000080000006D696D65747970656170706C69636174696F6E2F657075622B7A6970504B0304140000080800DD}
	%mpg  #{000001b4}
	%mp4  #{00000018667479706D7034F2000000016D7034F26D70343100000BE66D6F}

	;; ISO-BMFF files that also list isom/mp41/mp42 as compatible brands (must not be %mp4)
	%3gp  #{00000018 66747970 33677034 00000200 69736F6D 33677034} ;; ftyp 3gp4 [isom 3gp4]
	%3g2  #{00000018 66747970 33673261 00000000 69736F6D 33673261} ;; ftyp 3g2a [isom 3g2a]
	%f4v  #{00000018 66747970 46345620 00000000 69736F6D 6D703432} ;; ftyp F4V  [isom mp42]
	%m4b  #{00000018 66747970 4D344220 00000000 4D344120 69736F6D} ;; ftyp M4B  [M4A  isom]
	%m4p  #{00000018 66747970 4D345020 00000000 4D344120 69736F6D} ;; ftyp M4P  [M4A  isom]
	%cr3  #{00000018 66747970 63727820 00000001 63727820 69736F6D} ;; ftyp crx  [crx  isom]
	%mov  #{00000014 66747970 71742020 00000000 71742020}          ;; ftyp qt   [qt  ]
	%m4v  #{0000001C 66747970 4D345620 00000001 4D345620 4D344120 6D703432} ;; ftyp M4V  (size 0x1C)
	%m4v  #{00000020 66747970 4D345620 00000001 4D345620 4D344120 6D703432 69736F6D} ;; ftyp M4V  [M4V  M4A  mp42 isom]
	%m4v  #{00000018 66747970 4D345648 00000001 4D345648 6D703432} ;; ftyp M4VH [M4VH mp42]

	;; HEIF with mif1/msf1 major brand; heic/avif as the first compatible brand (offset 16)
	%heic #{00000018 66747970 6D696631 00000000 68656963 6D696631} ;; ftyp mif1 [heic mif1]
	%avif #{00000018 66747970 6D696631 00000000 61766966 6D696631} ;; ftyp mif1 [avif mif1]
	%heic #{0000001C 66747970 6D736631 00000000 6D736631 69736F36 68656963} ;; ftyp msf1 [msf1 iso6 heic]
	%heic #{00000018 66747970 6D736631 00000000 6D736631 68657663} ;; ftyp msf1 [msf1 hevc]
	%heic #{00000018 66747970 68657663 00000000 6D736631 68657663} ;; ftyp hevc [msf1 hevc]
	%heic #{00000018 66747970 68656978 00000000 6D696631 68656978} ;; ftyp heix [mif1 heix]

	;; formerly duplicated rules
	%asf  #{3026B275 8E66CF11 A6D900AA 0062CE6C}                  ;; ASF header GUID (wmv/wma)
	%xcf  #{67696D70 20786366 2066696C 6500}                      ;; "gimp xcf file^@"
	%xcf  #{67696D70 20786366 20763031 3100}                      ;; "gimp xcf v011^@"
	%amr  #{2321414D 520A}                                        ;; "#!AMR^/"
	%amr  #{2321414D 522D5742 0A}                                 ;; "#!AMR-WB^/"

	%avi  #{52494646 F4F00100 41564920 4C495354}                   ;; "RIFF....AVI LIST"
	%mov  #{00017F42 6D6F6F76 0000006C 6D766864}                   ;; QuickTime without ftyp: moov atom first
	%mov  #{00000008 77696465 0001F0B8 6D646174}                   ;; QuickTime without ftyp: wide + mdat
	%webm #{1A45DFA3 01000000 00000010 42828577 65626D00 42878102} ;; DocType "webm^@"
	%webm #{1A45DFA3 9F 428284 7765626D 42878102}                  ;; DocType "webm"
	%mkv  #{1A45DFA3 A3 428289 6D617472 6F736B61 00 42878104}      ;; DocType "matroska^@"
	%mkv  #{1A45DFA3 A3 428288 6D617472 6F736B61 42878104}         ;; DocType "matroska"
	%vtt  #{57454256 5454}                                         ;; "WEBVTT" at EOF
	%vtt  #{57454256 54540A0A}                                     ;; "WEBVTT^/^/"
	%vtt  #{EFBBBF 57454256 54540A}                                ;; UTF-8 BOM + "WEBVTT^/"
	%tar  (tar-v7)                                                 ;; v7 tar without ustar magic

	;; Ogg subtypes by the first packet's codec header
	%opus #{4F676753 00020000 00000000 00000102 03040000 0000AABB CCDD0113 4F707573 48656164}
	%ogv  #{4F676753 00020000 00000000 00000102 03040000 0000AABB CCDD0113 80746865 6F7261}
	%ogm  #{4F676753 00020000 00000000 00000102 03040000 0000AABB CCDD0113 01766964 656F00}
	%spx  #{4F676753 00020000 00000000 00000102 03040000 0000AABB CCDD0113 53706565 78202020}
	%oga  #{4F676753 00020000 00000000 00000102 03040000 0000AABB CCDD0113 7F464C41 43}
	%ogg  #{4F676753 00020000 00000000 00000102 03040000 0000AABB CCDD0113 01766F72 626973}
	%ogx  #{4F676753 00020000 00000000 00000102 03040000 0000AABB CCDD0113 00000000 00000000}

	;; formerly missing variants
	%xml  #{EFBBBF 3C3F786D 6C207665 7273696F 6E3D}                ;; UTF-8 BOM + "<?xml version="
	%tiff #{49492B00 08000000 10000000 00000000}                   ;; BigTIFF little-endian
	%tiff #{4D4D002B 00080000 00000000 00000010}                   ;; BigTIFF big-endian
	%cpio #{C7710000}                                              ;; binary cpio little-endian
	%cpio #{71C70000}                                              ;; binary cpio big-endian

	;; must not be identified
	#(none) #{7801 010500FAFF 68656C6C6F 062C0215}                ;; zlib stream (was %dmg)
	#(none) #{52494646 41564920 4A554E4B}                          ;; "RIFFAVI JUNK" (AVI in size field)
	#(none) #{7B202020 20202022 57454250 223A207B 7D7D0A}          ;; JSON text mentioning "WEBP"
	#(none) #{57454256 545458}                                     ;; "WEBVTTX"
	#(none) (tar-bad)                                              ;; v7 tar header with wrong checksum
][
	result: identify file
	prin [result TAB if result [mime-type? join %. result]]
	print either result != type [
		++ failed
		[as-red " FAILED!" "Expected type:" type]
	][	"" ]
]

if failed > 0 [quit/return failed]