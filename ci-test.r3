Rebol []

try [system/modules/identify: none]
try [unset 'identify]

import %identify.reb
import mime-types

failed: 0

foreach [type file] [
	avif %fixtures/sample.avif
	dds  %fixtures/sample.dds
;	doc  %fixtures/sample.doc
;	docx %fixtures/sample.docx
	gif  %fixtures/sample.gif
	heic %fixtures/sample.heic
	jp2  %fixtures/sample.jp2
	jpg  %fixtures/sample.jpg
	jxl  %fixtures/sample.jxl
	m4a  %fixtures/sample.m4a
	mov  %fixtures/sample.mov
	mp4  %fixtures/sample.mp4
;	odp  %fixtures/sample.odp
;	ods  %fixtures/sample.ods
;	odt  %fixtures/sample.odt
	pdf  %fixtures/sample.pdf
	png  %fixtures/sample.png
;	ppt  %fixtures/sample.ppt
;	pptx %fixtures/sample.pptx
	tar  %fixtures/sample.tar
	tiff %fixtures/sample.tif
	wav  %fixtures/sample.wav
	webp %fixtures/sample.webp
;	xls  %fixtures/sample.xls
;	xlsx %fixtures/sample.xlsx
	zip  %fixtures/sample.zip
	zst  %fixtures/sample.zst

	jpx  #{0000000C6A5020200D0A870A00000000667479706A707820}
	cr2  #{49492A00 00000000 4352}
	tiff #{49492A00 00000000 FFFF}
	mp3  #{FFFAAA}
	epub #{504B0304140000080000FC687D5A6F61AB2C1400000014000000080000006D696D65747970656170706C69636174696F6E2F657075622B7A6970504B0304140000080800DD}
	mpg  #{000001b4}
	mp4  #{00000018667479706D7034F2000000016D7034F26D70343100000BE66D6F}
][
	result: identify file
	prin [result TAB mime-type? join %. result]
	print either result != type [
		++ failed
		[as-red " FAILED!" "Expected type:" type]
	][	"" ]
]

if failed > 0 [quit/return failed]