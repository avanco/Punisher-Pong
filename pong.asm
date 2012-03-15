; Author: Lucas Avanço (avanco89 at gmail)
; based on "thin red line by Kirk Israel"
; based on Stella Programming Guide

	processor 6502
	include vcs.h
	org $F000

; Variables (memory region: $80 to $FF)
YPosBall = $80
BallSize = $81

Start			; init stuff:
	SEI			; no interruptions
	CLD			; clear BCD Math Bit
	LDX #$FF	; X to up
	TXS			; stack pointer = X
	LDA #0

ClearMem
	STA 0,X		; MEM[X+0] = Accumulator value
	DEX			; X--
	BNE ClearMem

	LDA #0
	STA YPosBall
	LDA #0
	STA BallSize

SetColors
	LDA #$44
	STA COLUBK	; background color
	LDA #$21		; defining PlayField size (D0) and Ball size (D4, D5)
	STA CTRLPF
	LDA #$10
	STA PF0

MainLoop
	LDA	#2		; VSYNC D1 = 1 --> turn off electron beam,
				;  position it at the top of the screen
	STA VSYNC	; VSYNC must be sent for at least 3 scanlines
	STA WSYNC	;  by TIA
	STA WSYNC
	STA WSYNC
	LDA #0		; -- CHECK IN-1
	STA VSYNC	; the time is over -- CHECK IN-1

	LDA #43		; 37 scanlines * 76 machine cycles = 2812
				; 2812 + 5 cycles(init timer) + 3 cycles(STA WSYNC) + 6 cycles(loop check)
				; Finally we have 2812-14=2798 cycles while VBLANK scanlines, and 2798/64=43
	STA TIM64T

	LDA #2		; -- CHECK IN-2
	STA VBLANK	; -- CHECK IN-2
	#LDA #0		; -- CHECK OUT-1
	#STA VSYNC	; the time is over -- CHECK OUT-1

	; game logic, timer is running
	DEC YPosBall
	LDA YPosBall
	BNE WaitVBlankEnd
	LDA #0
	STA YPosBall
	

WaitVBlankEnd
	LDA INTIM	; load timer
	BNE WaitVBlankEnd	; killing time if the timer != 0
	; 37 VBLANK scanlines has gone
	
	LDY #191	; count scanlines
	STA WSYNC	; wait for scanline end, we do not wanna begin at the middle of one
	STA VBLANK	; VBLANK D1 = 0

	LDA #$F0	; speed
	STA HMBL
	LDA #$10	; speed
	STA HMM0
	STA WSYNC
	STA HMOVE	; strobe register like WSYNC

ScanLoop
	STA WSYNC

	CPY YPosBall		; check if we are at ball position, scanline
	BEQ ActiveBallSize	;
	LDA BallSize		;
	BNE Drawing			;
NoBall					;
	LDA #0				;
	STA ENABL			;
	JMP Continue		;
ActiveBallSize			;
	LDA #8				;
	STA BallSize		;
Drawing					;
	LDA #2				;
	STA ENABL			;
	DEC BallSize		;
Continue
	LDA #2
	STA ENAM0
; check collision
	LDA #%1000000
	BIT CXM0FB
	BEQ NoCollision
	STY COLUBK	; background color
	STA CXCLR
NoCollision
	DEY
	BNE ScanLoop

	LDA #2
	STA WSYNC
	STA VBLANK	; turn it on, actual tv picture has gone

	; Overscan
	LDX #30
OverScanWait
	STA WSYNC
	DEX
	BNE OverScanWait

	JMP MainLoop

; Kirk Israel words:
; OK, last little bit of crap to take care of.
; there are two special memory locations, $FFFC and $FFFE
; When the atari starts up, a "reset" is done (which has nothing to do with
; the reset switch on the console!) When this happens, the 6502 looks at
; memory location $FFFC (and by extension its neighbor $FFFD, since it's 
; seaching for both bytes of a full memory address)  and then goes to the 
; location pointed to by $FFFC/$FFFD...so our first .word Start tells DASM
; to put the binary data that we labeled "Start" at the location we established
; with org.  And then we do it again for $FFFE/$FFFF, which is for a special
; event called a BRK which you don't have to worry about now.
 
	org $FFFC
	.word Start
	.word Start
