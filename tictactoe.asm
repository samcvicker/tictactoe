.include "Header.inc"
;.include "Snes_Init.asm"
.include "InitSNES.asm"

.bank 0 slot 0
.org 0
.section "VBlank"
;---------------
VBlank:
	RTI
;---------------
.ends


.bank 0 slot 0
.org 0
.section "Main"
;---------------
Start:
	;Snes_Init
	InitSNES
	;--LOADING THE PALETTE	
	rep #%00010000	;16 bit xy
	sep #%00100000	;8 bit ab

	ldx #$0000	;take every byte from the palette, put in CGRAM
 
-	lda UntitledPalette.l, x
	sta $2122
	inx
	cpx #8
	bne -

	lda #33		;loading only one color for the second palette
	sta $2121
	lda.l Palette2
	sta $2122
	lda.l Palette2+1
	sta $2122

	ldx #UntitledData	;address of UntitledData
	lda #:UntitledData
	ldy #(15*16*2)		;length of UntitledData
	stx $4302		;write
	sta $4304
	sty $4305
	lda #%00000001
	sta $4300
	lda #$18		;$211[89]: VRAM data write (???)
	sta $4301		;set destination

	ldy #$0000		;write to VRAM from $0000
	sty $2116		;2116 is the vra address

	lda #%00000001		;start DMA, channel 0
	sta $420B		;DMA address is 420 lol!!!

	lda #%10000000		;VRAM writing mode
	sta $2115
	ldx #$4000
	stx $2116		;write to VRAM from $4000

;_____________________________________
	.rept 2
	;------
	.rept 2
	ldx #$0000	;tile 0 ( )
	stx $2118
	ldx $0002	;tile 2 (|)
	stx $2118
	.endr
	;------
	ldx #$0000
	stx $2118
	
	;first line done, add BGs?
	;------
	.rept 27
	stx $2118	; X = O
	.endr
	;------

	;beginning of 2nd line
	;-+-+-
	.rept 2
	ldx #$0004	; tile 4 (-)
	stx $2118
	ldx #$0006	; tile 6 (+)
	stx $2118
	.endr
	;------

	ldx #$0004	; tile 4 (-)
	stx $2118
	ldx #$0000

	;------
	.rept 27
	stx $2118
	.endr
	;------
	
	.endr
;_______________________________________

	.rept 2
	ldx #$0000	; tile 0 ( )
	stx $2118
	ldx #$0002	; tile 2 (|)
	stx $2118
	.endr

	ldx #$6000	; BG 2 will start here!
	stx $2116
	ldx #$000C	; contains one tile
	stx $2118

	;settin up the screenNNNNNNNNNNNNNN
	lda #%00110000	;16x16 tiles, mode 0
	sta $2105	;screen mode register
	lda #%01000000	;data starts from $4000 & $6000
	sta $2107	;for BG1
	lda #%01100000	
	sta $2108	;for BG2

	stz $210B	;BG! & 2 use the $0000 tiles

	lda #%00000011	;enable bg 1 and 2
	sta $212C

	; the ppu doesn't process the top line, so we scroll down one
	rep #$20	;16bit a
	lda #$07FF	;this is -1 for BG1
	sep #$20	;8bit a
	sta $210E	;BG1 vert scroll
	xba
	sta $210

	rep #$20	;16bit a
	lda #$FFFF	;this is -1 for BG2
	sep #$20	;8bit a
	sta $2110	;BG2 vert scroll
	xba
	sta $2110
	
	lda #%00001111	;enable screen, set brightness to 15
	sta $2100
	
	lda #%10000001	;enable NMI and joypads
	sta $4200

forever:
	wai
	jmp forever
;--------------------
.ends

.bank 1 slot 0
.org 0
.section "Tiledata"
.include "tiles.inc"
.ends
