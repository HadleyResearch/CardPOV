;************************************************************
; File: cardpov1_3.asm
; Programmer: George Hadley
; Description: Version 1 source code for POV Business card project
; Device: pic18f25j50
; Program History:
;	Date		Ver					Description
; 10-19-09		1.0		Initial program created
; 11-08-09		1.0		tmr0 interrupt code created, pov table added,
;						main loop created
; 11-28-09		1.1		Code rewrite for PIC18F25J50
; 01-19-10		1.2		First stable version created
; 01-19-10		1.3		Multiple string support code initiated, scroll left code elliminated
; 01-30-10		1.3		Multiple string support code worked on, button issue unsolved
; 02-08-10		1.3		Button issue resolved, multiple string support code completed
;
; To-Do-List:
; X) Oscillator initialization code
; X) Initialization code
; X) Timer Interrupt Code
; X) Button debounce code
; X) POV character code
; X) Multiple string support
;
; Notes:
; 1) Pin Usage:
;	Pin		Port					Description
;	2 		RA0			Pushbutton 1 (momentary contact to ground)
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

	#include "pov_table4.inc"

	;Configuration bit setup
	config 	WDTEN = off				;Disable watchdog timer
	config 	PLLDIV = 1				;No PLL prescale
	config	STVREN = off			;Disable stack overflow/underflow reset
	config	XINST = off				;Disable extended instruction set
	config	CP0 = off				;Disable program memory code protection
	config	OSC = INTOSC			;Use internal chip oscillator
	config	T1DIG = off				;Disable secondary oscillator clock source selection
	config	LPT1OSC = off			;Low power timer 1 oscillator high power operation
	config	FCMEN = on				;Enable fail-safe clock monitor
	config	IESO = off				;Disable internal/external oscillator switch over mode
	config	WDTPS = 1				;1:1 watchdog postscaler
	config	DSWDTOSC = INTOSCREF	;DSWDT uses INTRC
	config	RTCOSC = INTOSCREF		;RTCC uses INTRC
	config	DSBOREN = off			;DSBOR disabled
	config	DSWDTEN	= off			;DSWDT disabled
	config	DSWDTPS = 2				;1:2 (2.1 ms)
	config 	IOL1WAY = OFF			;IOCLOCK bit can be set and cleared
	config	MSSP7B_EN = MSK7		;7-bit address masking mode
	config	WPCFG = OFF				;Configuration words page not write protected
	config	WPDIS = OFF				;WPFP[5:0],WPEND,and WPCFG bits ignored

	cblock ;add global variables here
	  pbctrl	;pushbutton control register
	  povctrl	;pov control register
	  sign_width ;width of led sign
	  sign_width2 ;copy of sign_width variable
	  counter	;sign counter variable
	  povlow	;low portion of POV output
	  povhigh	;high portion of POV output
	  numpov	;number of loaded pov signs
	  numpov2	;copy of num_pov variable
	  povdatu	;upper byte of pov data address
	  povdath	;high byte of pov data address
	  povdatl	;low byte of pov data address
	  povu		;upper byte of pov sign address
	  povh		;high byte of pov sign address
	  povl		;low byte of pov sign address
	endc
	;Add any definitions here
	;Pushbutton control register
	#define button1 	PORTA,0		;Pushbutton 1 Alias
	#define prevpb1 	pbctrl,0 	;Previous state of pb1
	#define	pb1			pbctrl,1	;pb1 press flag
	#define	timer_high	0xFF
	#define	timer_low	0xA1
	;POV control register
	#define	povdir		povctrl,0	;POV direction bit
	#define	updatepov	povctrl,1	;POV update flag

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

tmr0_interrupt
	;Timer0 Interrupt service routine
	bcf		INTCON,tmr0if	;Important: Clear interrupt flag
					;(wouldn't want to be trapped in an isr, would we?)
	;reload tmr0 to trigger in 375 cycles of operation
	movlw	timer_high
	movwf	TMR0H	;Timer0 to trigger ever y 375 clock cycles
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
	movlb	0Fh		;Set bank select register to F (needed to access ANCON0 register)
	clrf	PORTA	;Clear port a output latches
	movlw	07h		
	movwf	CM1CON	;Configure Comparator for digital operation
	clrf	CVRCON	;Disable comparator voltage reference enable
	setf	ANCON0	;Configure ADC for digital operation
	clrf	ADCON0
	movlw	0x03
	movwf	TRISA
	clrf	PORTB	;clear portb to be used as an output
	clrf	TRISB
	clrf	PORTC
	clrf	TRISC

	;Timer Initialization
	movlw	0x85	;Enable, select 16-bit mode, 1:64 prescaler
	movwf	T0CON
	movlw	timer_high
	movwf	TMR0H	;Timer0 to trigger every 375 clock cycles
	movlw	timer_low
	movwf	TMR0L	;Write to TMR0L updates entire TMR0 register
	;Interrupt Initialization
	bcf		INTCON,TMR0IF	;Clear timer0 interrupt flag
	bsf		INTCON,TMR0IE	;Enable timer0 overflow interrupts
	bsf		INTCON,GIE		;Enable global interrupts

	;User variable initializations
	movlw	0x01
	movwf	pbctrl
	;bcf		pb1				
	;bsf		prevpb1		
	movlw	segcount
	movwf	counter
	movlw	0x3F			;Initialize povlow to mask lower 6 bits of POV output
	movwf	povlow
	movlw	0x60			;Initialize povhigh to mask 7th bit of POV output
	movwf	povhigh
	clrf	numpov
	clrf	numpov2
	clrf	sign_width
	clrf	sign_width2

init_pov					;Load POV table data from 0800h, load number of signs
	movlw	0x00
	movwf	tblptrl
	movlw	0x08
	movwf	tblptrh
	movlw	0x00
	movwf	tblptru
	tblrd*+
	movff	tablat,numpov	;Load number of POV signs
	movff	numpov,numpov2	;Create copy of POV sign number
	incf	tblptrl
main
	call	load_pov
main2
	;load initial pov string value
	movff	povl,tblptrl
	movff	povh,tblptrh
	movff	povu,tblptru
	movff	sign_width,sign_width2
main3
	;wait until updatepov condition is set (done during timer0 interrupt), else, sit in wait loop
	btfsc	pb1
	bra		load_povdat
	btfss	updatepov
	bra	 	main3
	;if update pov condition is met...
	bcf		updatepov
	bra		scroll_right	;if end of sign is not reached, update output with latest POV character
load_povdat
	movff	povdatu,tblptru
	movff	povdath,tblptrh
	movff	povdatl,tblptrl
	decfsz	numpov2					;load povdatu,povdath,povdatl for next sign
	bra		main			;reload data table if out of strings
reload_table						;If end of strings is reached
	movff	numpov,numpov2
	movlw	0x00					;  reload table at 0801h
	movwf	tblptru
	movlw	0x08
	movwf	tblptrh
	movlw	0x02
	movwf	tblptrl
	bra		main
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
	decfsz	sign_width2		;switch directions if right side of POV sign is reached
	bra		main3
	bra		main2			;reload POV sign if end of sign is reached

;****************************************************************
; Function: load_pov
; Description: Load number of segments and starting address for
;	current POV sign
; Note: tblptr should be set up before this function is called
;****************************************************************
load_pov
	tblrd*+
	movff	tablat,sign_width		;acquire length of pov sign
	movff	sign_width,sign_width2	;copy length of pov sign
	tblrd*+
	movff	tablat,povu				;save upper address of pov sign
	tblrd*+							;acquire high address of pov sign
	movff	tablat,povh				;save high address of pov sign
	tblrd*+
	movff	tablat,povl				;save low address of pov sign
 	movff	tblptru,povdatu			;save next sign data location
	movff	tblptrh,povdath
	movff	tblptrl,povdatl
	bra		end_load_pov

end_load_pov
	return
	end