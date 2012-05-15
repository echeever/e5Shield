/*
 *  ======== CSL_init.c ========
 *  DO NOT MODIFY THIS FILE - CHANGES WILL BE OVERWRITTEN
 */
 
/* external peripheral initialization functions */
extern void GPIO_init(void);
extern void BCSplus_init(void);
extern void USCI_B0_init(void);
extern void Timer0_A3_init(void);
extern void System_init(void);
extern void WDTplus_init(void);

#include <msp430.h>

/*
 *  ======== CSL_init =========
 *  Initialize all configured CSL peripherals
 */
void CSL_init(void)
{
    /* Stop watchdog timer from timing out during initial start-up. */
    WDTCTL = WDTPW + WDTHOLD;

    /* initialize Config for the MSP430 GPIO */
    GPIO_init();

    /* initialize Config for the MSP430 2xx family clock systems (BCS) */
    BCSplus_init();

    /* initialize Config for the MSP430 USCI_B0 */
    USCI_B0_init();

    /* initialize Config for the MSP430 A3 Timer0 */
    Timer0_A3_init();

    /* initialize Config for the MSP430 System Registers */
    System_init();

    /* initialize Config for the MSP430 WDT+ */
    WDTplus_init();

}

/*
 *  ======== Interrupt Function Definitions ========
 */
/* --COPYRIGHT--,EPL
 *  Copyright (c) 2010 Texas Instruments and others.
 *  All rights reserved. This program and the accompanying materials
 *  are made available under the terms of the Eclipse Public License v1.0
 *  which accompanies this distribution, and is available at
 *  http://www.eclipse.org/legal/epl-v10.html
 * 
 *  Contributors:
 *      Texas Instruments - initial implementation
 * 
 * --/COPYRIGHT--*/

/* Interrupt Function Prototypes */







