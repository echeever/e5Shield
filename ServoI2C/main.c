/* ======== Standard MSP430 includes ======== */
#include <msp430.h>

#define FALSE 			0
#define TRUE  			!FALSE
#define DISABLESERVO	251
#define RESET_I2C_STATE	252
#define	LEDP1_0			13

enum i2cStates { WAITING, GETVAL} volatile i2cState = WAITING;
enum pwmStates { MSEC1, MSECVAR, MSEC18 } volatile pwmState = MSEC18;

const char bitMask[] = {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80};

volatile unsigned char srvVals[9];
volatile unsigned char srvNum;
volatile int msecCnt = 0;
volatile unsigned char updateFlag = FALSE;
volatile unsigned char startUpdateFlag = FALSE;
volatile unsigned char pulseFlag = FALSE;
volatile unsigned char ngFlag = FALSE;	// For debugging only - this should never be true.
unsigned volatile char srvs[256]; // this needn't be global - easier for debugging.

/* ======== Grace related includes ======== */
#include <ti/mcu/msp430/csl/CSL.h>

/* ======== main ======== */
int main(int argc, char *argv[]) {
	int i,j,k;						// generic loop counters.
	unsigned volatile char servoMask;

    CSL_init();                     // Activate Grace-generated configuration

    for (i=0;i<4;i++) {					// BLink LED twice (sanity cheS0ck)
    	for (j=0;j<4000;j++)			// Delay
    		for (k=0;k<100;k++);
    	P1OUT ^= 1;
    }

    // Initialization
    servoMask  = 0x00;
    for (i=0; i<8; i++) srvVals[i] = DISABLESERVO;
    for (i=0; i<256; i++) srvs[i] = 0;

    IE2 |= UCB0RXIE;                // Enable RX interrupt
    TA0CCTL0 = CCIE;                // CCR0 interrupt enabled

	while (1) {
		switch (pwmState) {
		case MSEC1:  				// During first millisecond
			P2OUT = servoMask; 		//  all enabled servos have high outputs.
			break;
		case MSECVAR:				// During second millisecond
			if (pulseFlag) {
				for (i=0; i<=250; i++) {//  put out variable duration
					P2OUT = srvs[i];	//  pulse.
					for (j=0; j<9; j++);// Delay for 4 uSec
					asm(" NOP"); asm(" NOP"); asm(" NOP"); asm(" NOP");
				}
				pulseFlag = FALSE;
			}
			break;
		case MSEC18:
			P2OUT = 0x00;  			//  all servos outputs are low.
			if (msecCnt == 0) {
				servoMask=0x00;
				for (j=0; j<8; j++) {
					if (srvVals[j]<=250) servoMask |= 1 << j;
				}

				for (i=250; i>=0; i--) {  		//
		    		int servosOn = 0;
	   	    		for (j=0; j<8; j++) {		// For each motor
		   	    		if (i<srvVals[j]) servosOn |= 1 << j;
		   	    	}
		   	    	srvs[i] = servosOn & servoMask;
		    	}

				if (srvVals[8] & 0x01) P1OUT |= BIT0;
				else P1OUT &= ~BIT0;
			}
	 		break;
		default: ngFlag=TRUE;
    	}
    }
}

#pragma vector = USCIAB0TX_VECTOR
__interrupt void i2cRcvInt(void) {
	static volatile char i2cByte;
	i2cByte = UCB0RXBUF;
	switch (i2cState) {
	case WAITING:
		srvNum = i2cByte;
		i2cState = GETVAL;
		break;
	case GETVAL:
		if (srvNum <= 8) srvVals[srvNum] = i2cByte;
		i2cState = WAITING;
		break;
	default:
		i2cState = WAITING;	ngFlag=TRUE;
	}
	if (i2cByte == RESET_I2C_STATE) {
		i2cState = WAITING;
	}
}


#pragma vector=TIMER0_A0_VECTOR
__interrupt void mSecInt(void) {
	switch (pwmState) {		// state machine servo pulse width assignments
	case MSEC1:
		pwmState=MSECVAR;	// from state MSEC1 in first millisecond, move to MSECVAR
		pulseFlag = TRUE;
		break;
	case MSECVAR:
		pwmState=MSEC18;	// from MSECVAR in the second millisecond, move to MSEC18
		msecCnt=0;			// reset millisecond counter
		break;
	case MSEC18:
		if (msecCnt++ > 16) pwmState=MSEC1;	 // stay in state MSEC18 for 18 msec
		break;
	default:
		pwmState=MSEC18;
		ngFlag=TRUE;
	}
}

/*
 * srvNum = 0-7, this is the number of the servo to be written
 * srvNum = 8 (ASCII:"="), this is an LED connect to P1.0 on E5Shield
  */
