.include "Header.inc"
.include "Snes_Init.asm"

;--------------
.macro ConvertX
;Data in: our coordinate in A
;Data out: SNES scroll data in C (the 16 bit A)
.rept 5
asl a	;multiply A by 32
.endr
rep #%00100000	;16 bit A
eor #$FFFF	;this will do A=1-A
inc a		
sep #%00100000	;8 bit A
.endm
;--------------

;--------------
.macro ConvertY
;sama data in & out as b4
.rept 5
asl a
.endr
rep #%00100000
eor #$FFFF
sep #%00100000
.endm
;--------------


.bank 0 slot 0
.org 0
.section "VBlank"
;---------------
VBlank:
	lda $4212	;get joypad status
	and #%00000001	;if joypad is not ready
	bne VBlank	;wait
	lda $4219	;read joypad (low byte ((only polling B,Y,
			;SELECT, START, Up,Dn,L,R)))
	sta $0201	;store it
	cmp $0200	;compare it with the previous
	bne +		;if not equal, go forward to next plus sign
	rti		;if equal, return (return from interrupt)

+	sta $0200	;store
	and #%00010000	;get the start button
			;this will be the delete key
	beq +		; if it's 0, we don't have to delete
	ldx #$0000
-	stz $0000,x	;delete addresses $0000 to $0008
	inx
	cpx #$09
	bne -
	stz $0100	;delete the scroll
	stz $0101	;and data

+	lda $0201	;get back the temp value
	and #%11000000	;getting specifically B AND Y
	beq +		;if empty, skip this
	;	B or Y is pressed.
	;press B to place an O
	;press Y to place an X
	cmp #%11000000	;both are pressed?
	beq +		;then don't do anything
	cmp #%10000000	;Just B?
	bne ++		;if no, try Y
	;so B is pressed, write an O ($08)
	;we have to tell the cursor position & calculate
	;an address from that using this Formula:
	;	Address = 3 * Y + X
	lda $0101	;get Y
	sta $0202	;put it to a temp value
	clc		;clear carry
	adc $0202	;Multiply By 3 Easiest Way Tutorial
	adc $0202	; A*3 = A+A+A
	adc $0100	;add X
	;now A contains our Address

	ldx #$0000
	tax		;Transfer A -> X
	lda #$08
	sta $0000,x	; put $08 to the good address
	jmp +

++	cmp #%01000000	;now check for Y
	bne +		;if not pressed, jump forward
			;technically should not happen
	
	;so Y is pressed, write an X ($0A)
	lda $0101	;get Y
	sta $0202	;put it to a temp value
	clc
	adc $0202
	adc $0202
	adc $0100
	ldx #$0000
	tax
	lda #$0A
	sta $0000,x

	;now for cursor movement
+	lda $0201	;get control input
	and #%00001111	;ONLY CHECKS FOR DPAD MOVEMENT
	sta $0201	;store this in A
	
	cmp #%00001000	;up?
	bne +		;if not, skip
	lda $0101	;get scroll Y
	cmp #$00	;if on the top,
	beq +		;don't do anything
	dec $0101	;subtract 1 from Y

+	lda $0201	;get control again
	cmp #%00000100	;down?
	bne +		;if not, skip
	lda $0101
	cmp #$02	;if on the bottom,
	beq +		;don't do anything
	inc $0101	; increase Y by 1

+	lda $0201	;get control again
	cmp #%00000010	;left?
	bne +
	lda $0100
	cmp #$00
	beq +
	dec $0100

+	lda $0201
	cmp #%00000001	;right?
	bne +
	lda $0100
	cmp #$02
	beq +
	inc $0100

+	rti

;---------------
.ends


.bank 0 slot 0
.org 0
.section "Main"
;---------------
Start:
	Snes_Init
	
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
	lda #$18		;$211[89]: VRAM data write 
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
	;X|X|X
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
	sta $210E

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
	
	rep #%00100000	;get 16 bit A
	lda #$0000	;empty it
	sep #%00100000	;get 8 bit A
	lda $0100	;get our X coordinate
	 ConvertX
	sta $210F	;BG2 vertical scroll
	xba
	sta $210F	;write 16 bits
	
	;now repeat that, but change $0100 to $0101
	;and also change $210F to $2110
	rep #%00100000
	lda #$0000
	sep #%00100000
	lda $0101	;get Y coordinate
	 ConvertY
	sta $2110	;BG2 vert scroll
	xba
	sta $2110

	ldx #$0000	;reset counter
-	rep #%00100000	;16 bit A
	lda #$0000	;empty it
	sep #%00100000	;8 bit A
	lda VRAMtable.l, x	;long-indexed address
	rep #%00100000
	clc
	adc #$4000	;add $4000 to the value & carry bit on
	sta $2116	;write to VRAM from here
	lda #$0000	;reset A while it's still 16 bit
	sep #%00100000
	lda $0000,x	;get the corresponding tile from RAM
	;VRAM data write mode is still %10000000
	sta $2118
	stz $2119
	inx
	cpx #9		;finished?
	bne -		;if not, go back!

	jmp forever
;--------------------
.ends

.bank 1 slot 0
.org 0
.section "Tiledata"
.include "tiles.inc"
.ends

.bank 2 slot 0
.org 0
.section "Conversiontable"
;-------------------------
VRAMtable:
	.db $00, $02, $04, $40, $42, $44, $80, $82, $84
;-------------------------
.ends

