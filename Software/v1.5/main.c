/**************************************************************
* File: main.c
* Description: main source code file for CardPOV v1.5, a C code
*	rewrite of previous CardPOV ASM code
* Author: George Hadley
* Program History:
*	Date	Ver					Description
* 8/21/10 	0.0		Initial program file created
* 8/23/10	0.0		Device initializations added, InitPIC function
*					completed
* 8/24/10	0.0		povctrl,pbctrl classes completed
* 
* Notes:
* 1) Pin Usage:
*	Pin		Port					Description
*	11		RC0			Pushbutton 1 (momentary contact to ground)
*	10,7-2	RA6-RA0		POV LEDs
*
* 2) Status and Control Registers
*	pbctrl: pushbutton control register
*	Bit		Name					Description
*	0		prevpb1		Bit to store the previous state of pushbutton 1 (PortC,0)
*	1		pb1			Flag bit to indicate pb1 has been pressed
*
*	povctrl: POV control register
*   Bit		Name					Description
*	0		povdir		POV direction bit (1: forward, 0:reverse)
*	1		updatepov	POV update flag
*
* 3) Perform device configurations using the #pragma config directive
*
* To-Do List:
*	1) Create initial working version of code
*	2) Build in multiple string support (MSS)
**************************************************************/
#include<p18f25j50.h>
#include "aliases.h"
#include "povtable.h"

//Device configuration pragmas: options are hidden in the device .inc file
#pragma config WDTEN=OFF,PLLDIV=1,CPUDIV=OSC1,OSC=INTOSC,DSBOREN=OFF
#pragma config DSWDTEN=OFF,XINST=OFF

void main();
void initPIC();
void povSetup();
void updatePOV();

//Timer0 Interrupt Service Routine
void __ISR _T0Interrupt () {
	//Place interrupt code here	
} //end _T0Interrupt

//System-level PIC initializations
void initPIC() {
	OSCCON = 0x73;

	//IO Initializations
	PORTA 	= 0x00;
	LATA 	= 0x00;
	TRISA 	= 0x00;
	PORTB 	= 0x00;
	LATB 	= 0x00;
	TRISB 	= 0x00;
	PORTC 	= 0x00;
	LATC 	= 0x00;
	TRISC 	= 0x01;	//Use bottom bit of PORTC as input
	
	//Timer initializations
	T0CON = 0x84;
	TMR0H = TIMER_HIGH;
	TMR0L = TIMER_LOW;

	//Interrupt Initializations
	INTCONbits.TMR0IF = 0;	//Clear tmr0 interrupt flag
	INTCONbits.TMR0IE = 1;	//Enable timer 0 interrupts
	INTCONbits.GIE = 1;		//Enable all interrupts
} //end initPIC()

void povSetup() {
	sign_width = POVSEGSR;
	//WORK IN PROGRESS
} //end povSetup()

void updatePOV() {
	if(povctrlbits.updatepov == 1) {
		//increment table read entry
		//mask table value against povlow
		//mask table value against povhigh
		//store povlow, povhigh masked results into portb and portc
		sign_width--;
	}
} //end updatePOV()

void main() {
	initPIC();
	//User variable declarations/initializations
	pbctrlbits.pb1 = 0;
	pbctrlbits.prevpb1 = 1;
	povctrlbits.povdir = 1;		//POV display initially scrolls forward
	char counter = SEGCOUNT;	//Counter register
	char povlow = 0x3F;			//Initialize povlow to mask lower 6 bits of POV output
	char povhigh = 0x60;		//Initialize povhigh to mask 7th bit of POV output
	char sign_width;			//Width of POV sign

	while(1) {
		povSetup();				//Set up POV display
		while(sign_width > 0) {
			updatePOV();
		} //end while(sign_width > 0)
	} //end while(1)
} //end main()	