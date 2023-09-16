; vdp
; This is code for the TMS9918A
; kw
; 2023-05-31
; 2023-09-11	convert to asx format

; current EVB expansion bus address:

data		.equ	0xd800
ctrl		.equ	0xd801

; VDP colour definitions:

bkblue		.equ	0x04	;user config - blue bkg)
bkred		.equ	0x06	;user config - blue bkg)
bkgrn		.equ	0x0C	;user config - blue bkg)
bkblk		.equ	0x01	;user config - black bkg)
bkgrey		.equ	0x0E	;user config - black bkg)

patcol		.equ	0xE0	;gray on x

; 9918A hardware code

lsprit		.equ	208	;last sprite marker

; program section

	.hd6303
        .area   SYS (ABS,OVR)
	.org	0xb800		;EVB auto execute address

; put config register init values address into registers

		ldx	#gmode2
		ldab	#0x80		;TMS9918 table address format

; do begin
; transfer a byte

next:		ldaa	,x		;A = byte
		bsr	wrctrl		;B = control register
		inx			;next config byte
		incb		
		cmpb	#0x88
		bne next
; end

; fill pattern generator table

		ldaa	#0x00
		ldab	#0x40
		bsr	wrctrl	;set up for writes starting at 0x0000

		ldx	#ctable	;point to char table
		stx	U0	;count = size of table

		ldx	#0
nexp:
		pshx
		ldx	U0
		ldab	0,x
		stab	data	;transfer to VRAM
		bsr	DLY10MS
		inx
		cpx	#ctend
		bne	nexch
		ldx	#ctable	;point to char table again
nexch:
		stx	U0
		pulx

		inx
		cpx	#0x1800	;size of patt gen table
		bne	nexp

; fill pattern colour table
		ldaa	#0x00
		ldab	#0x60
		bsr	wrctrl	;set up for writes starting at 0x2000

		ldx	#0x1800		; table size
nexp2:
		stx	U1
		ldab	U1		;get upper byte of counter
		andb	#0x0F		;mask to 4 bits

		ldaa	U1+1	;get lower order byte
		lsla
		anda	#0xF0
		staa	U1+1

		orab	U1+1
		stab	data
		bsr	DLY10MS
		dex
		bne	nexp2

; fill pattern name table

		ldaa	#0x00
		ldab	#0x78
		bsr	wrctrl	;set up for writes starting at 0x3800

		ldab	#0	; will increment
		ldx	#0x300	; table size

nexp3:		stab	data
		bsr	DLY10MS
		incb
		dex
		bne	nexp3

; configure sprites
		ldaa	#0x00
		ldab	#0x7B
		bsr	wrctrl	;set up for writes starting at 0x1800

		ldab	#s0	; make first sprite the only
		stab	data

		ldaa	#0x00
		ldab	#0x7B
		bsr	wrctrl	;set up for writes starting at 0x3B00

		ldab	#s0attr	; make first sprite the only
		stab	data

; finished setup, go back to monitor

		rts

; write the control register
; in order A,B

wrctrl:		staa	ctrl
		bsr	DLY10MS
		stab	ctrl
		bsr	DLY10MS
		rts

; borrowed delay routine

DLY10MS:	PSHX          ;delay ?? at E = 2MHz
		LDX  #0x0080
DLYLP:		DEX
		BNE  DLYLP
		PULX
		RTS

; data section

U0:		.rmb	2	; count bytes to fill pattern gen
U1:		.rmb	2	; temp for x reg sampling

;	Custom values
;	Graphics Mode 2

;	0000-17FF	Pattern Gen
;	1800-1FFF	Sprite Generator (Patterns)
;	2000-37FF	Pattern Colour
;	3800-3AFF	Pattern Name
;	3B00-3B80	Sprite Attribute

gmode2:		.fcb	0x02	;M3=1,ext vid disable
		.fcb	0xc2	;16K DRAM, Blank=1, G2 mode, SIZ=1, MAG=0
		.fcb	0x0E	;Pattern Name table 0x0E*0x400 = 0x3800
		.fcb	0xFF	;Pattern Colour table 0x80*0x40 = 0x2000
				;!!! LSB's == 1
		.fcb	0x03	;Pattern Gen 0*0x800 = 0x0000
				;!!! LSB's == 1
		.fcb	0x76	;Sprite Attr 0x76*0x80 = 0x3B00
		.fcb	0x03	;Sprite Pattern Gen 0x03*0x800 = 0x1800
		.fcb	bkblue

;	Ciarcia values
;	Graphics Mode 2

ciarci:		.fcb	0x02	;M3=1
		.fcb	0xc2	;16K DRAM, Blank=1, G2 mode, SIZ=1, MAG=0
		.fcb	0x01	;Name table 1*0x400 = 0x400
		.fcb	0x03	;Colour table 3*0x40 = 0x0C0
		.fcb	0x01	;Pattern Gen 1*0x800 = 0x800
		.fcb	0x0e	;Sprite Attr 0x0e*0x80 = 0x700
		.fcb	0x00	;Sprite Pattern Gen 0*0x800 = 0x0000
		.fcb	bkred

; 	TI values
;	Graphics Mode 1 3.3 VRAM addressing example

itab:		.fcb	0x00	;ext VDP dis, M3=0
		.fcb	0xc0	;16K DRAM, Blank=1, G2 mode, SIZ=0, MAG=0
		.fcb	0x01	;Name table 0x400
		.fcb	0x08	;Colour table 0x0200
		.fcb	0x01	;Pattern Gen 0x800
		.fcb	0x02	;Sprite Attr 0x100
		.fcb	0x00	;Sprite Pattern Gen 0x0000
		.fcb	bkblue	;user config - blue bkg)


; 	TI values
;	Graphics Mode Multicolour

multic:		.fcb	0x00	;ext VDP dis, M3=0
		.fcb	0xc8	;16K DRAM, Blank=1, Multicolour mode, SIZ=0, MAG=0
		.fcb	0x01	;Name table 0x400
		.fcb	0x08	;Colour table 0x0200
		.fcb	0x01	;Pattern Gen 0x800
		.fcb	0x02	;Sprite Attr 0x100
		.fcb	0x00	;Sprite Pattern Gen 0x0000
		.fcb	bkblue	;user config - blue bkg)

; 	TI values
;	text mode

textab:		.fcb	0x00	;ext VDP dis, M3=0
		.fcb	0xd0	;16K DRAM, Blank=1, text mode, SIZ=0, MAG=0
		.fcb	0x01	;Name table 0x400
		.fcb	0x08	;Colour table 0x0200
		.fcb	0x01	;Pattern Gen 0x800
		.fcb	0x02	;Sprite Attr 0x100
		.fcb	0x00	;Sprite Pattern Gen 0x0000
		.fcb	0x31	;gray on black
;

; from https://github.com/dhepper/font8x8/blob/master/font8x8_basic.h

	.org	0xba00

ctable:

    .fcb 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ;U+0020 (space)
    .fcb 0x18, 0x3C, 0x3C, 0x18, 0x18, 0x00, 0x18, 0x00 ;U+0021 (!)
    .fcb 0x36, 0x36, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ;U+0022 (")
    .fcb 0x36, 0x36, 0x7F, 0x36, 0x7F, 0x36, 0x36, 0x00 ;U+0023 (#)
    .fcb 0x0C, 0x3E, 0x03, 0x1E, 0x30, 0x1F, 0x0C, 0x00 ;U+0024 ($)
    .fcb 0x00, 0x63, 0x33, 0x18, 0x0C, 0x66, 0x63, 0x00 ;U+0025 (%)
    .fcb 0x1C, 0x36, 0x1C, 0x6E, 0x3B, 0x33, 0x6E, 0x00 ;U+0026 (&)
    .fcb 0x06, 0x06, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00 ;U+0027 (')
    .fcb 0x18, 0x0C, 0x06, 0x06, 0x06, 0x0C, 0x18, 0x00 ;U+0028 (()
    .fcb 0x06, 0x0C, 0x18, 0x18, 0x18, 0x0C, 0x06, 0x00 ;U+0029 ())
    .fcb 0x00, 0x66, 0x3C, 0xFF, 0x3C, 0x66, 0x00, 0x00 ;U+002A (*)
    .fcb 0x00, 0x0C, 0x0C, 0x3F, 0x0C, 0x0C, 0x00, 0x00 ;U+002B (+)
    .fcb 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C, 0x06 ;U+002C (,)
    .fcb 0x00, 0x00, 0x00, 0x3F, 0x00, 0x00, 0x00, 0x00 ;U+002D (-)
    .fcb 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C, 0x00 ;U+002E (.)
    .fcb 0x60, 0x30, 0x18, 0x0C, 0x06, 0x03, 0x01, 0x00 ;U+002F (/)
    .fcb 0x3E, 0x63, 0x73, 0x7B, 0x6F, 0x67, 0x3E, 0x00 ;U+0030 (0)
    .fcb 0x0C, 0x0E, 0x0C, 0x0C, 0x0C, 0x0C, 0x3F, 0x00 ;U+0031 (1)
    .fcb 0x1E, 0x33, 0x30, 0x1C, 0x06, 0x33, 0x3F, 0x00 ;U+0032 (2)
    .fcb 0x1E, 0x33, 0x30, 0x1C, 0x30, 0x33, 0x1E, 0x00 ;U+0033 (3)
    .fcb 0x38, 0x3C, 0x36, 0x33, 0x7F, 0x30, 0x78, 0x00 ;U+0034 (4)
    .fcb 0x3F, 0x03, 0x1F, 0x30, 0x30, 0x33, 0x1E, 0x00 ;U+0035 (5)
    .fcb 0x1C, 0x06, 0x03, 0x1F, 0x33, 0x33, 0x1E, 0x00 ;U+0036 (6)
    .fcb 0x3F, 0x33, 0x30, 0x18, 0x0C, 0x0C, 0x0C, 0x00 ;U+0037 (7)
    .fcb 0x1E, 0x33, 0x33, 0x1E, 0x33, 0x33, 0x1E, 0x00 ;U+0038 (8)
    .fcb 0x1E, 0x33, 0x33, 0x3E, 0x30, 0x18, 0x0E, 0x00 ;U+0039 (9)
    .fcb 0x00, 0x0C, 0x0C, 0x00, 0x00, 0x0C, 0x0C, 0x00 ;U+003A (:)
    .fcb 0x00, 0x0C, 0x0C, 0x00, 0x00, 0x0C, 0x0C, 0x06 ;U+003B (;)
    .fcb 0x18, 0x0C, 0x06, 0x03, 0x06, 0x0C, 0x18, 0x00 ;U+003C (<)
    .fcb 0x00, 0x00, 0x3F, 0x00, 0x00, 0x3F, 0x00, 0x00 ;U+003D (=)
    .fcb 0x06, 0x0C, 0x18, 0x30, 0x18, 0x0C, 0x06, 0x00 ;U+003E (>)
    .fcb 0x1E, 0x33, 0x30, 0x18, 0x0C, 0x00, 0x0C, 0x00 ;U+003F (?)
    .fcb 0x3E, 0x63, 0x7B, 0x7B, 0x7B, 0x03, 0x1E, 0x00 ;U+0040 (@)
    .fcb 0x0C, 0x1E, 0x33, 0x33, 0x3F, 0x33, 0x33, 0x00 ;U+0041 (A)
    .fcb 0x3F, 0x66, 0x66, 0x3E, 0x66, 0x66, 0x3F, 0x00 ;U+0042 (B)
    .fcb 0x3C, 0x66, 0x03, 0x03, 0x03, 0x66, 0x3C, 0x00 ;U+0043 (C)
    .fcb 0x1F, 0x36, 0x66, 0x66, 0x66, 0x36, 0x1F, 0x00 ;U+0044 (D)
    .fcb 0x7F, 0x46, 0x16, 0x1E, 0x16, 0x46, 0x7F, 0x00 ;U+0045 (E)
    .fcb 0x7F, 0x46, 0x16, 0x1E, 0x16, 0x06, 0x0F, 0x00 ;U+0046 (F)
    .fcb 0x3C, 0x66, 0x03, 0x03, 0x73, 0x66, 0x7C, 0x00 ;U+0047 (G)
    .fcb 0x33, 0x33, 0x33, 0x3F, 0x33, 0x33, 0x33, 0x00 ;U+0048 (H)
    .fcb 0x1E, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00 ;U+0049 (I)
    .fcb 0x78, 0x30, 0x30, 0x30, 0x33, 0x33, 0x1E, 0x00 ;U+004A (J)
    .fcb 0x67, 0x66, 0x36, 0x1E, 0x36, 0x66, 0x67, 0x00 ;U+004B (K)
    .fcb 0x0F, 0x06, 0x06, 0x06, 0x46, 0x66, 0x7F, 0x00 ;U+004C (L)
    .fcb 0x63, 0x77, 0x7F, 0x7F, 0x6B, 0x63, 0x63, 0x00 ;U+004D (M)
    .fcb 0x63, 0x67, 0x6F, 0x7B, 0x73, 0x63, 0x63, 0x00 ;U+004E (N)
    .fcb 0x1C, 0x36, 0x63, 0x63, 0x63, 0x36, 0x1C, 0x00 ;U+004F (O)
    .fcb 0x3F, 0x66, 0x66, 0x3E, 0x06, 0x06, 0x0F, 0x00 ;U+0050 (P)
    .fcb 0x1E, 0x33, 0x33, 0x33, 0x3B, 0x1E, 0x38, 0x00 ;U+0051 (Q)
    .fcb 0x3F, 0x66, 0x66, 0x3E, 0x36, 0x66, 0x67, 0x00 ;U+0052 (R)
    .fcb 0x1E, 0x33, 0x07, 0x0E, 0x38, 0x33, 0x1E, 0x00 ;U+0053 (S)
    .fcb 0x3F, 0x2D, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00 ;U+0054 (T)
    .fcb 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x3F, 0x00 ;U+0055 (U)
    .fcb 0x33, 0x33, 0x33, 0x33, 0x33, 0x1E, 0x0C, 0x00 ;U+0056 (V)
    .fcb 0x63, 0x63, 0x63, 0x6B, 0x7F, 0x77, 0x63, 0x00 ;U+0057 (W)
    .fcb 0x63, 0x63, 0x36, 0x1C, 0x1C, 0x36, 0x63, 0x00 ;U+0058 (X)
    .fcb 0x33, 0x33, 0x33, 0x1E, 0x0C, 0x0C, 0x1E, 0x00 ;U+0059 (Y)
    .fcb 0x7F, 0x63, 0x31, 0x18, 0x4C, 0x66, 0x7F, 0x00 ;U+005A (Z)
    .fcb 0x1E, 0x06, 0x06, 0x06, 0x06, 0x06, 0x1E, 0x00 ;U+005B ([)
    .fcb 0x03, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x40, 0x00 ;U+005C (\)
    .fcb 0x1E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x1E, 0x00 ;U+005D (])
    .fcb 0x08, 0x1C, 0x36, 0x63, 0x00, 0x00, 0x00, 0x00 ;U+005E (^)
    .fcb 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF ;U+005F (_)
    .fcb 0x0C, 0x0C, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00 ;U+0060 (`)
    .fcb 0x00, 0x00, 0x1E, 0x30, 0x3E, 0x33, 0x6E, 0x00 ;U+0061 (a)
    .fcb 0x07, 0x06, 0x06, 0x3E, 0x66, 0x66, 0x3B, 0x00 ;U+0062 (b)
    .fcb 0x00, 0x00, 0x1E, 0x33, 0x03, 0x33, 0x1E, 0x00 ;U+0063 (c)
    .fcb 0x38, 0x30, 0x30, 0x3e, 0x33, 0x33, 0x6E, 0x00 ;U+0064 (d)
    .fcb 0x00, 0x00, 0x1E, 0x33, 0x3f, 0x03, 0x1E, 0x00 ;U+0065 (e)
    .fcb 0x1C, 0x36, 0x06, 0x0f, 0x06, 0x06, 0x0F, 0x00 ;U+0066 (f)
    .fcb 0x00, 0x00, 0x6E, 0x33, 0x33, 0x3E, 0x30, 0x1F ;U+0067 (g)
    .fcb 0x07, 0x06, 0x36, 0x6E, 0x66, 0x66, 0x67, 0x00 ;U+0068 (h)
    .fcb 0x0C, 0x00, 0x0E, 0x0C, 0x0C, 0x0C, 0x1E, 0x00 ;U+0069 (i)
    .fcb 0x30, 0x00, 0x30, 0x30, 0x30, 0x33, 0x33, 0x1E ;U+006A (j)
    .fcb 0x07, 0x06, 0x66, 0x36, 0x1E, 0x36, 0x67, 0x00 ;U+006B (k)
    .fcb 0x0E, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x1E, 0x00 ;U+006C (l)
    .fcb 0x00, 0x00, 0x33, 0x7F, 0x7F, 0x6B, 0x63, 0x00 ;U+006D (m)
    .fcb 0x00, 0x00, 0x1F, 0x33, 0x33, 0x33, 0x33, 0x00 ;U+006E (n)
    .fcb 0x00, 0x00, 0x1E, 0x33, 0x33, 0x33, 0x1E, 0x00 ;U+006F (o)
    .fcb 0x00, 0x00, 0x3B, 0x66, 0x66, 0x3E, 0x06, 0x0F ;U+0070 (p)
    .fcb 0x00, 0x00, 0x6E, 0x33, 0x33, 0x3E, 0x30, 0x78 ;U+0071 (q)
    .fcb 0x00, 0x00, 0x3B, 0x6E, 0x66, 0x06, 0x0F, 0x00 ;U+0072 (r)
    .fcb 0x00, 0x00, 0x3E, 0x03, 0x1E, 0x30, 0x1F, 0x00 ;U+0073 (s)
    .fcb 0x08, 0x0C, 0x3E, 0x0C, 0x0C, 0x2C, 0x18, 0x00 ;U+0074 (t)
    .fcb 0x00, 0x00, 0x33, 0x33, 0x33, 0x33, 0x6E, 0x00 ;U+0075 (u)
    .fcb 0x00, 0x00, 0x33, 0x33, 0x33, 0x1E, 0x0C, 0x00 ;U+0076 (v)
    .fcb 0x00, 0x00, 0x63, 0x6B, 0x7F, 0x7F, 0x36, 0x00 ;U+0077 (w)
    .fcb 0x00, 0x00, 0x63, 0x36, 0x1C, 0x36, 0x63, 0x00 ;U+0078 (x)
    .fcb 0x00, 0x00, 0x33, 0x33, 0x33, 0x3E, 0x30, 0x1F ;U+0079 (y)
    .fcb 0x00, 0x00, 0x3F, 0x19, 0x0C, 0x26, 0x3F, 0x00 ;U+007A (z)
    .fcb 0x38, 0x0C, 0x0C, 0x07, 0x0C, 0x0C, 0x38, 0x00 ;U+007B ({)
    .fcb 0x18, 0x18, 0x18, 0x00, 0x18, 0x18, 0x18, 0x00 ;U+007C (|)
    .fcb 0x07, 0x0C, 0x0C, 0x38, 0x0C, 0x0C, 0x07, 0x00 ;U+007D (})
    .fcb 0x6E, 0x3B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ;U+007E (~)
    .fcb 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ;U+007F

ctend:

s0:
		.fdb 0xFF80, 0x8080, 0x8080, 0x8080
s0attr:
		.fcb 0x40, 0x60, 0x00, 0x03
		.fcb lsprit

; end program
HERE	.equ	.

	.END