;************************************************************
; File: cardpov1_5.asm
; Programmer: George Hadley
; Description: Version 1 source code for POV Business card project
; Device: pic18f25j50
; Program History:
;	Date		Ver					Description
; 10-19-09		0.0		Initial program created
; 11-08-09		0.0		tmr0 interrupt code created, pov table added,
;						main loop created
; 11-28-09		1.0		Code rewrite for PIC18F25J50
;
; To-Do-List:
; X) Oscillator initialization code
; X) Initialization code
; X) Timer Interrupt Code
; X) Button debounce code
; X) POV character code
; 6) Multiple string support
;
; Notes:
; 1) Pin Usage:
;	Pin		Port					Description
;	11		RC0			Pushbutton 1 (momentary contact to ground)
;	10,7-2	RA6-RA0		POV LEDs
;
; 2) Status and Control Registers
;	pbctrl: pushbutton control register
;	Bit		Name					Description
;	0		prevpb1		Bit to store the previous state of pushbutton 1 (PortC,0)
;	1		pb1			Flag bit to indicate pb1 has been pressed
;
;	povctrl: POV control register
;   Bit		Name					Description
;	0		povdir		POV direction bit (1: forward, 0:reverse)
;	1		updatepov	POV update flag
;
; 3) When using timer0 in 16-bit mode, the upper byte (tmr0h) is not updated
;	 until a write occurs to the lower byte.
; 4) On the PIC18f2550, RC3 is not implemented and RC4 and RC5 must be used
;	 for USB or only as digital inputs
;************************************************************
	#include<p18f25j50.inc>
	list p = p18f25j50, r = dec

	#include "pov_table.inc"
	;Configuration bit setup
	cblock ;add global variables here
	  pbctrl	;pushbutton control register
	  povctrl	;pov control register
	  sign_width ;width of led sign
	  counter	;sign counter variable
	  povlow	;low portion of POV output
	  povhigh	;high portion of POV output
	endc
	;Add any definitions here
	;Pushbutton control register
	#define button1 	PORTC,0		;Pushbutton 1 Alias
	#define prevpb1 	pbctrl,0 	;Previous state of pb1
	#define	pb1			pbctrl,1	;pb1 press flag
	#define	timer_high	0xFF
	#define	timer_low	0xA1
	;POV control register
	#define	povdir		povctrl,0	;POV direction bit
	#define	updatepov	povctrl,1	;POV update flag
	#define povsegsr 67			;Constant for number of segments (57)
	#define	povsegsl 189		;(199)
	#define segcount 1			;timing divider
	org		0
	;Oscillator initialization
	clrf 	bsr		;Clear bank select register
					;(should be clear by default, but just in case)
	movlw	0x73	;Set Internal Oscillator to active
					;oscillator, frequency = 8MHz
	movwf	OSCCON
	bra		initialize

	org		08
interrupt
	;Timer0 Interrupt service routine
	bcf		INTCON,tmr0if	;Important: Clear interrupt flag
					;(wouldn't want to be trapped in an isr, would we?)
	;reload tmr0 to trigger in 375 cycles of operation
	movlw	timer_high
	movwf	TMR0H	;Timer0 to trigger every 375 clock cycles
	movlw	timer_low
	movwf	TMR0L	;Write to TMR0L updates entire TMR0 register

	btfsc	button1	;set pb1 if prevpb1 = 1 and button1 = 0	
	bra		no_button1	
	btfss	prevpb1
	bra		set_prevpb1
	bsf		pb1
	bcf		prevpb1
	bra		update
set_prevpb1	;code for button1 = 1
	bcf		pb1
	bcf		prevpb1
	bra		update
no_button1
	bsf		prevpb1
	bcf		pb1
update
	;Update POV every 4th interrupt
	decfsz	counter
	bra 	exit_tmr0
	movlw	segcount
	movwf	counter
	bsf		updatepov	;Flag main loop to update POV output
exit_tmr0	
	retfie

initialize
	;General I/O Initialization
	clrf	PORTB	;clear portb to be used as an output
	clrf	TRISB
	clrf	LATC
	clrf	PORTC
	movlw	0x01	;Use top bit of PORTC as output
	movwf	TRISC
	clrf	LATA	;Clear port a output latches
	clrf	TRISA	;Port A to be used as POV output
	
	;Timer Initialization
	movlw	0x84	;Enable, select 16-bit mode, 1:32 prescaler
	movwf	T0CON
	movlw	timer_high
	movwf	TMR0H	;Timer0 to trigger every 375 clock cycles
	movlw	timer_low
	movwf	TMR0L	;Write to TMR0L updates entire TMR0 register
	;Interrupt Initialization
	bcf		INTCON,TMR0IF	; Clear timer0 interrupt flag
	bsf		INTCON,TMR0IE	;Enable timer0 overflow interrupts
	bsf		INTCON,GIE		;Enable global interrupts

	;User variable initializations
	bcf		pb1				
	bsf		prevpb1		
	bsf		povdir			;POV initially scrolls forward	
	movlw	segcount
	movwf	counter
	movlw	0x3F			;Initialize povlow to mask lower 6 bits of POV output
	movwf	povlow
	movlw	0x60			;Initialize povhigh to mask 7th bit of POV output
	movwf	povhigh
main
	;load POV sign with correct character count
	movlw	povsegsr
	movwf	sign_width
	;load initial pov string value
	movlw	low(pov_string2)
	movwf	tblptrl
	movlw	high(pov_string2)
	movwf	tblptrh
	movlw	upper(pov_string2)
	movwf	tblptru
main2
	;wait until updatepov condition is set (done during timer0 interrupt), else, sit in wait loop
	btfss	updatepov
	bra	 	main2
	;if update pov condition is met...
	bcf		updatepov
;	btfss	povdir			;Check POV scroll direction, scroll left if povdir=0
;	bra		shift_left		;Branch to left scroll condition
;	bsf		portb,5			;Flash assist light (supposed to help determine which direction to scroll)
	bra		scroll_right	;if end of sign is not reached, update output with latest POV character
;	movlw	povsegsl
;	movwf	sign_width
;	bcf		povdir
;	bra		scroll_left
;shift_left
;	bcf		portb,5
;	incfsz	sign_width		;switch directions if left side of POV sign is reached
;	bra		scroll_left
;	movlw	povsegsr
;	movwf	sign_width
;	bsf		povdir			;Fall through to scroll_right instruction
;	bra		scroll_right
scroll_right 				;Display sign character (scroll right)
	tblrd*+
	movf	tablat,w
	andwf	povlow,f		;Mask lower 6 bits of POV output
	andwf	povhigh,f		;Mask 7th bit of POV output
	rlncf	povhigh
	movff	povlow,portb	;Load lower 6 bits of POV output
	movff	povhigh,portc	;Load 7th bit of POV output
	movlw	0x3F			;Reload povload to mask lower 6 bits of POV output
	movwf	povlow
	movlw	0x60			;Reload povhigh to mask 7th bit of POV output
	movwf	povhigh
	decfsz	sign_width		;switch directions if right side of POV sign is reached
	bra		main2
	bra		main			;reload POV sign if end of sign is reached
;scroll_left
;	tblrd*-
;	movff	tablat,porta
;	bra		main2
;no_scroll
;	tblrd*
;	movff	tablat,porta
;	bra		main2
;	
;pov_string1 ;pov character data (string 1)
;	de	0x00,0x00,0x00,0x00,0x00		;Buffer
;	de	0x00,0x00,0x00,0x00,0x00		;Buffer
;	de	0x7F,0x10,0x08,0x04,0x7F,0x00	;N
;	de	0x7F,0x49,0x49,0x49,0x36,0x00	;B
;	de	0x2F,0x00						;i
;	de	0x10,0x10,0x3F,0x10,0x10,0x00	;t
;	de	0x7E,0x01,0x0E,0x01,0x7E,0x00	;W
;	de	0x1F,0x11,0x11,0x1F,0x00		;o
;	de	0x1F,0x10,0x10,0x1F,0x00		;n
;	de	0x1F,0x11,0x11,0x7F,0x00		;d
;	de	0x1F,0x15,0x15,0x1D,0x00		;e
;	de	0x1F,0x10,0x10					;r
;	de	0x00,0x00,0x00,0x00,0x00		;Buffer
;	de	0x00,0x00,0x00,0x00,0x00		;Buffer

;pov_string2	;pov character data (string 2)
;	de		0x00,0x00,0x00,0x00,0x00		;Buffer
;	de		0x00,0x00,0x00,0x00,0x00		;Buffer
;	de		0x00,0x7F,0x04,0x08,0x10,0x7F	;N
;	de		0x00,0x7F,0x49,0x49,0x49,0x36	;B
;	de		0x00,0x7A						;i
;	de		0x04,0x7E,0x04					;t
;	de		0x00,0x7F,0x40,0x38,0x40,0x3F	;W
;	de		0x00,0x7C,0x44,0x44,0x7C		;o
;	de		0x00,0x7C,0x04,0x04,0x7C		;n
;	de		0x00,0x7C,0x44,0x44,0x7F		;d
;	de		0x00,0x7C,0x54,0x54,0x5C		;e
;	de		0x00,0x7C,0x04,0x04				;r
;	de		0x00,0x00,0x00,0x00,0x00		;Buffer
;	de		0x00,0x00,0x00,0x00,0x00		;Buffer
;end_string1
	end