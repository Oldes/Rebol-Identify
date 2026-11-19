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
][
	unless binary? file [file: read/part/binary file 262]
	foreach [type rule] types [
		if type: parse file [rule to end (return type)][
			return type
		]
	]
	none
]

types: make map! [
	%mid  [
		#{4D546864} |
		#{534D4632434C4950} ; https://www.iana.org/assignments/media-types/audio/midi-clip
	]
	%m4a  [#{4D344120} | 4 skip #{667479704D3441}]
	%ogg   #{4F676753}
	%flac  #{664C6143}
	%wav  [#{52494646} 4 skip #{57415645}]
	%amr   #{2321414D52} ;= audio/amr ("#!AMR^/" or "#!AMR-WB^/")
	%aac  [#{FFF1} | #{FFF9}]
	%aif  [#{464F524D} 4 skip #{414946} [#"^(46)" | #"^(43)"]]
	%jls   #{FFD8FFF7} ;; JPG7/SOF55, indicating a ISO/IEC 14495 / JPEG-LS file
	%jpg   #{FFD8FF}
	%jpx  [#{0000000C} 12 skip #{667479706A707820}]
	%jp2  [#{0000000C} 12 skip #{667479706A703220}]
	%jpm  [#{0000000C} 12 skip #{667479706A706D20}]
	%mj2  [#{0000000C} 12 skip #{667479706D6A7032}]
	%jxl  [#{FF0A} | #{0000000C4A584C200D} skip #{870A}]
	%apng [#{89504e470d0a1a0a} to #{6163544C}] ;; simplified!
	%png   #{89504E47}
	%gif   #{474946}
	%webp [#{52494646} 4 skip #{574542505650}]
	%cr2  [[#{49492A00} | #{4D4D002A}] 4 skip #{4352}]
	%tiff [[#{49492A00} | #{4D4D002A}] 4 skip not #{4352} | #{49492B00} | #{4D4D002B}] ;; TIFF | BigTIFF
	%bmp   #{424D}
	%jxr   #{4949BC}
	%psd   #{38425053}
	%heic [
		isobmf
		[
			#{68656963} | ;heic
			[
				#{6D696631} | ;mif1
				#{6D736631}   ;msf1
			] 4 skip [#{68656963} | 4 skip #{68656963} | 8 skip #{68656963} | 12 skip #{68656963}]
		]
	]
	%dcm  [128 skip #{4449434D}]
	%dwg   #{41433130}
	%xcf   #{67696D702078636620} ;= image/x-xcf ("gimp xcf file" or "gimp xcf v...")
	%avif [
		isobmf
		[
			#{61766966} | ;avif
			#{61766973} | ;avis
			[
				#{6D696631} | ;mif1
				#{6D736631}   ;msf1
			] 4 skip [#{61766966} | 4 skip #{61766966} | 8 skip #{61766966} | 12 skip #{61766966}]
		]
	]
	%qoi   #{716F6966}
	%dds   #{44445320}
	%rpm   #{edabeedb}
	%epub [#{504B0304} 26 skip #{6D696D65747970656170706C69636174696F6E2F657075622B7A6970}]
	%zip  [#{504B} [#"^(03)" | #"^(05)" | #"^(07)"] [#"^(04)" | #"^(06)" | #"^(08)"] return (%zip)]
	%rar  [#{526172211A07} [#"^(00)" | #"^(01)"]]
	%gz    #{1F8B08}
	%bz2   #{425A68}
	%7z    #{377ABCAF271C}
	%pdf  [opt #{EFBBBF} #{25504446}]
	%exe   #{4D5A}
	%swf  [#{465753} | #{435753} | #{5A5753}]
	%rtf   #{7B5C727466} ;= application/rtf
	%nes   #{4E45531A}   ;= application/x-nintendo-nes-rom
	%crx   #{43723234}   ;= application/x-google-chrome-extension
	%cab  [#{4D534346} | #{49536328}] ;= application/vnd.ms-cab-compressed
	;%eot [8 skip [#{020001} | #{010000} | #{020002}] 23 skip #{4C50}] ;= application/octet-stream
	%eps  [
		#{C5D0D3C6} |
		#{252150532D41646F62652D} 3 skip #{20455053462D} ;= "%!PS-Adobe-XXX EPSF-XXX"
	] 
	%ps     #{2521}
	%xz     #{FD377A585A00}
	%sqlite #{53514C69}
	%deb    #{213C617263683E0A64656269616E2D62696E617279}
	%ar     #{213C617263683E}
	%z     [#{1FA0} | #{1F9D}]
	%lzop   #{894C5A4F000D0A1A}
	%lz     #{4C5A4950}
	%elf   [#{7F454C46} 48 skip]
	%lz4    #{04224D18}
	%br     #{ceb2cf81}
	%zst   [[#"^(22)" | #"^(23)" | #"^(24)" | #"^(25)" | #"^(26)" | #"^(27)" | #"^(28)"] #{B52FFD}] ;! only Zstandard frames

	
	%m4v   [isobmf #{4D3456}] ;; M4V , M4VH, M4VP
	%mkv   [#{1A45DFA3} to #{428288 6D6174726F736B61}]
	%webm  [#{1A45DFA3} to #{428284 7765626D}]
	;; ISO-BMFF rules checking a specific major brand must precede %mp4,
	;; which also matches by compatible brands (isom/mp41/mp42)
	%mov   [
		isobmf #{71742020}
		;; QuickTime without ftyp box: moov, mdat, wide, free, skip or pnot atom first
		| 4 skip [#{6D6F6F76} | #{6D646174} | #{77696465} | #{66726565} | #{736B6970} | #{706E6F74}]
	]
	%3g2    [isobmf #{336732}]
	%3gp    [isobmf #{336770}]
	%f4a    [isobmf #{46344120}]
	%f4b    [isobmf #{46344220}]
	%f4p    [isobmf #{46345020}]
	%f4v    [isobmf #{46345620}]
	%m4b    [isobmf #{4D344220}]
	%m4p    [isobmf #{4D345020}]
	%mp4   [isobmf [mp4_brand | 8 skip [mp4_brand | 4 skip mp4_brand | 8 skip mp4_brand] ]]
	%avi   [#{52494646} 4 skip #{41564920}]
	%asf     #{3026B2758E66CF11A6D9}
	%flv    #{464C5601}
	%mpg   [#{000001} mpg_ver]

	%wasm  [#{0061736d} skip 3 null]

	%tar   [257 skip #{7573746172}]


	%ac3     #{0B77}
	%cpio   [#{C771} | #{71C7} | [#{3037303730} [#"^(37)" | #"^(31)" | #"^(32)"]]]
	%arj     #{60EA}
	%mpc    [#{4D502B} | #{4D50434B}]
	%avro    #{4F626A01} ;= application/avro
	%flif    #{464C4946} ;= image/flif
	%icns    #{69636E73} ;= image/icns
	%woff   [#{774F4646} [#{00010000} | #{4F54544F}]] ;= font/woff
	%woff2  [#{774F4632} [#{00010000} | #{4F54544F}]] ;= font/woff2
	%pcap   [#{D4C3B2A1} | #{A1B2C3D4}] ;= application/vnd.tcpdump.pcap
	%dsf    #{44534420} ;= audio/x-dsf
	%bpg    #{425047FB} ;= image/bpg
	%wv     #{7776706B} ;= audio/wavpack
	%ape    #{4D414320} ;= audio/ape
	%pst    #{2142444E} ;= application/vnd.ms-outlook
	%parquet  #{50415231} ;= application/x-parquet
	%ttc    #{74746366}   ;= font/collection
	%macho  #{CFFAEDFE}   ;= application/x-mach-binary
	%otf    #{4F54544F00} ;= font/otf
	%it     #{494D504D}   ;= audio/x-it
	%lzh  [ ;= application/x-lzh-compressed
		2 skip #{2D6C} [
			  #"^(68)" [#"^(30)" | #"^(31)" | #"^(32)" | #"^(33)" | #"^(34)" | #"^(35)" | #"^(36)" | #"^(37)" | #"^(64)"]
			| #"^(7A)" [#"^(73)" | #"^(34)" | #"^(35)"]
		]
	]
	%chm   #{49545346}   ;= application/vnd.ms-htmlhelp
	%class #{CAFEBABE}   ;= application/java-vm
	%rm    #{2E524D46}   ;= application/vnd.rn-realmedia
	%drc   #{445241434F} ;= application/vnd.google.draco
	%xml [
		#{3C3F786D6C20} |
		#{EFBBBF 3C3F786D6C20} |
		#{FFFE 3C003F0078006D006C00} |
		#{FEFF 003C003F0078006D006C}
	]
	%stl      #{736F6C696420} ;= model/stl
	%blend    #{424C454E444552}
	%vtt     [#{574542565454} [cr | lf | tab | sp | null]] ;= text/vtt
	%arrow    #{4152524F57310000} ;= application/x-apache-arrow
	%glb      #{676C544602000000} ;= model/gltf-binary
	%orf      #{4949524F0800000018} ;= image/x-olympus-orf
	%qcp     [#{52494646} 4 skip #{514C434D}]
	%rw2      #{494955001800000088E774D8}
	%ktx      #{AB4B5458203131BB0D0A1A0A}
	%mie     [[#{7E1004} | #{7E1804}] skip #{304D4945}]
	%shp     [2 skip #{270A} 10 null]
	%j2c      #{FF4FFF51}
	%cfb      #{D0CF11E0A1B11AE1}
	%icc      [36 skip #{61637370}]
	%ace      [7 skip #{2A2A4143452A2A}]
	%vcf      #{424547494E3A 5643415244}
	%ics      #{424547494E3A 5643414C454E444152}
	%raf      #{46554A4946494C4D4343442D524157}
	%xm       #{457874656E646564204D6F64756C653A}
	%voc      #{437265617469766520566F6963652046696C65}
	%asar  [
		#{04000000}
		12 skip #{7B2266696C6573223A} ;; checks for {"files":} string
		;; code bellow would work only if the buffer would be large enough!
		;; 8 skip pos: if (map? try [decode 'json binary/read skip b 12 'ui32lebytes])
	]
	%mxf   #{060E2B34020501010D0102010102}
	%s3m   [44 skip #{5343524D}]
	%mts   [
		;Raw MPEG-2 transport stream (188-byte packets)
		  #"^(47)" 187 skip #"^(47)"
		|
		;Blu-ray Disc Audio-Video (BDAV) MPEG-2 transport stream has 4-byte TP_extra_header before each 188-byte packet
		  4 skip #"^(47)" 191 skip #"^(47)"
	]
	%mobi   [60 skip #{424F4F4B4D4F4249}]
	%lnk     #{4C0000000114020000000000C000000000000046}
	%alias   #{626F6F6B000000006D61726B00000000}
	%fbx     #{4B617964617261204642582042696E6172792020001a}
	%eot    [8 skip [#{000001} | #{010002} | #{020002}] 23 skip #{4C50}]
	%indd    #{0606EDF5D81D46E5BD31EFE7FE74B71D}
	%pgp     #{2D2D2D2D2D424547494E20504750204D4553534147452D2D2D2D2D}
	%skp     #{FFFE FF0E53006B0065007400630068005500700020004D006F00640065006C00}
	%mp3    [#{494433} | mpg_sync if (0#02 == (pos and 0#06))]
	%mp2    [mpg_sync if (0#04 == (pos and 0#06))]
	%mp1    [mpg_sync if (0#06 == (pos and 0#06))]

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
mp4_brand: [#{6D703432} | #{6D703431} | #{69736F6D}]
isobmf: [4 skip #{66747970}]
pos: none
