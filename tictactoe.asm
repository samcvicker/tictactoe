.include "Header.inc"
.include "Snes_Init.asm"
.bank 1 slot 0
.org 0
.section "Tiledata"
.include "tiles.inc"
.ends

VBlank:
	RTI

Start:
	Snes_Init
	
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

	.rept 2
	  .rept 2
	    ldx #$0000	;tile 0 ( )
	    stx $2118
	    ldx $0002	;tile 2 (|)
	    stx $2118
	  .endr
	  ldx #$0000
	  stx $2118
	  ;first line done, add BGs?
	  .rept 27
	    stx $2118	; X = O
	  .endr
	
	  ;beginning of 2nd line
	  ;-+-+-
	  .rept 2
	    ldx #$0004	; tile 4 (-)
	    stx $2118
	    ldx #$0006	; tile 6 (+)
	    stx $2118
	  .endr
	  ldx #$0004	; tile 4 (-)
	  stx $2118
	  ldx #$0000
	  .rept 27
	    stx $2118
	  .endr
	.endr
	.rept 2
	  ldx #$0000	; tile 0 ( )
	  stx $2118
	  ldx #$0002	; tile 2 (|)
	  stx $2118
	.endr
