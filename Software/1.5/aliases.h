/**************************************************************
* File: aliases.h
* Description: aliases for CardPOV v1.5
**************************************************************/
#define TIMER_HIGH  0xFF
#define TIMER_LOW	0xA1

#define button1	PORTCbits.0

#define POVSEGSR 	67
#define POVSEGSL	189
#define SEGCOUNT	1

//pov control structure
extern volatile far unsigned char	povctrl;
extern volatile far struct {
	unsigned povdir:1;
	unsigned updatepov:1;
	unsigned :6;
} povctrlbits;

//pushbutton control structure
extern volatile far unsigned char	pbctrl;
extern volatile far struct {
	unsigned prevpb1:1;
	unsigned pb1:1;
	unsigned :6;
} pbctrlbits;
