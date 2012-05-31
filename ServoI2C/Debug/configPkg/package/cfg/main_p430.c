/*
 *  Do not modify this file; it is automatically 
 *  generated and any modifications will be overwritten.
 *
 * @(#) xdc-x20
 */

#define __nested__
#define __config__

#include <xdc/std.h>

/*
 * ======== GENERATED SECTIONS ========
 *     
 *     MODULE INCLUDES
 *     
 *     <module-name> INTERNALS
 *     <module-name> INHERITS
 *     <module-name> VTABLE
 *     <module-name> PATCH TABLE
 *     <module-name> DECLARATIONS
 *     <module-name> OBJECT OFFSETS
 *     <module-name> TEMPLATES
 *     <module-name> INITIALIZERS
 *     <module-name> FUNCTION STUBS
 *     <module-name> PROXY BODY
 *     <module-name> OBJECT DESCRIPTOR
 *     <module-name> SYSTEM FUNCTIONS
 *     <module-name> PRAGMAS
 *     
 *     INITIALIZATION ENTRY POINT
 *     PROGRAM GLOBALS
 *     CLINK DIRECTIVES
 */


/*
 * ======== MODULE INCLUDES ========
 */



/*
 * ======== xdc.cfg.Program TEMPLATE ========
 */

/*
 *  ======== __ASM__ ========
 *  Define absolute path prefix for this executable's
 *  configuration generated files.
 */
xdc__META(__ASM__, "@(#)__ASM__ = C:/Users/naaron1/Documents/GitHub/e5Shield/ServoI2C/Debug/configPkg/package/cfg/main_p430");

/*
 *  ======== __ISA__ ========
 *  Define the ISA of this executable.  This symbol is used by platform
 *  specific "exec" commands that support more than one ISA; e.g., gdb
 */
xdc__META(__ISA__, "@(#)__ISA__ = 430");

/*
 *  ======== __PLAT__ ========
 *  Define the name of the platform that can run this executable.  This
 *  symbol is used by platform independent "exec" commands
 */
xdc__META(__PLAT__, "@(#)__PLAT__ = ti.platforms.msp430");

/*
 *  ======== __TARG__ ========
 *  Define the name of the target used to build this executable.
 */
xdc__META(__TARG__, "@(#)__TARG__ = ti.targets.msp430.MSP430");

/*
 *  ======== __TRDR__ ========
 *  Define the name of the class that can read/parse this executable.
 */
xdc__META(__TRDR__, "@(#)__TRDR__ = ti.targets.omf.cof.Coff");


/*
 * ======== xdc.cfg.SourceDir TEMPLATE ========
 */



/*
 * ======== ti.catalog.msp430.init.Boot TEMPLATE ========
 */

    extern ti_catalog_msp430_init_Boot_disableWatchdog(UInt address);
    extern ti_catalog_msp430_init_Boot_configureDCO();

#if defined(__ti__)
#pragma CODE_SECTION(ti_catalog_msp430_init_Boot_init, ".text:.bootCodeSection")
#endif

/*
 *  ======== ti_catalog_msp430_init_Boot_init ========
 */
Void ti_catalog_msp430_init_Boot_init()
{
}



/*
 * ======== ti.mcu.msp430.csl.CSL TEMPLATE ========
 */

/* CSL stuff */

/*
 * ======== ti.mcu.msp430.csl.communication.USCI_B0 TEMPLATE ========
 */

/* USCI_B0 stuff from C:/ti/grace_1_10_00_17/packages/ti/mcu/msp430/csl/communication/./USCI_B0.xdt */

/*
 * ======== ti.mcu.msp430.csl.system.System TEMPLATE ========
 */

/* System stuff from C:/ti/grace_1_10_00_17/packages/ti/mcu/msp430/csl/system/./System.xdt */

/*
 * ======== ti.mcu.msp430.csl.timer.Timer0_A3 TEMPLATE ========
 */

/* Timer_A stuff from C:/ti/grace_1_10_00_17/packages/ti/mcu/msp430/csl/timer/./ITimer_A.xdt */

/*
 * ======== ti.mcu.msp430.csl.watchdog.WDTplus TEMPLATE ========
 */

/* WDTplus stuff from C:/ti/grace_1_10_00_17/packages/ti/mcu/msp430/csl/watchdog/./WDTplus.xdt */

/*
 * ======== ti.mcu.msp430.csl.gpio.GPIO TEMPLATE ========
 */

/* GPIO stuff from C:/ti/grace_1_10_00_17/packages/ti/mcu/msp430/csl/gpio/./GPIO.xdt */

/*
 * ======== ti.mcu.msp430.csl.clock.BCSplus TEMPLATE ========
 */

/* 2xx Clock stuff from C:/ti/grace_1_10_00_17/packages/ti/mcu/msp430/csl/clock/./BCSplus.xdt */

/*
 * ======== PROGRAM GLOBALS ========
 */


/*
 * ======== CONSTANTS ========
 */

