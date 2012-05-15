# default to compiling with debug information
CCOPTS ?= -g --symdebug:dwarf --optimize_with_debug -qq -pdsw225 

CC = C:/TI/ccsv5/tools/compiler/msp430/bin/cl430 -c --obj_directory=objs/ -D__MSP430G2553__  -vmsp -I C:/TI/ccsv5/tools/compiler/msp430/include 
AR = C:/TI/ccsv5/tools/compiler/msp430/bin/ar430 rq
RM = cmd.exe /q /c del /f
MKDIR = mkdir

# create object sub-directory, if necessary
ifeq (,$(wildcard objs/))
    $(shell $(MKDIR) objs\ )
endif

all: csl.lib

objs\CSL_init.obj: CSL_init.c
	@echo cl430 $< ...
	$(CC) $(CCOPTS) -I "C:/TI/grace_1_10_00_17/packages"  -I "C:/TI/grace_1_10_00_17/packages/ti/mcu/msp430//include" $<
	
objs\GPIO_init.obj: GPIO_init.c
	@echo cl430 $< ...
	$(CC) $(CCOPTS) -I "C:/TI/grace_1_10_00_17/packages"  -I "C:/TI/grace_1_10_00_17/packages/ti/mcu/msp430//include" $<
	
objs\BCSplus_init.obj: BCSplus_init.c
	@echo cl430 $< ...
	$(CC) $(CCOPTS) -I "C:/TI/grace_1_10_00_17/packages"  -I "C:/TI/grace_1_10_00_17/packages/ti/mcu/msp430//include" $<
	
objs\USCI_B0_init.obj: USCI_B0_init.c
	@echo cl430 $< ...
	$(CC) $(CCOPTS) -I "C:/TI/grace_1_10_00_17/packages"  -I "C:/TI/grace_1_10_00_17/packages/ti/mcu/msp430//include" $<
	
objs\Timer0_A3_init.obj: Timer0_A3_init.c
	@echo cl430 $< ...
	$(CC) $(CCOPTS) -I "C:/TI/grace_1_10_00_17/packages"  -I "C:/TI/grace_1_10_00_17/packages/ti/mcu/msp430//include" $<
	
objs\System_init.obj: System_init.c
	@echo cl430 $< ...
	$(CC) $(CCOPTS) -I "C:/TI/grace_1_10_00_17/packages"  -I "C:/TI/grace_1_10_00_17/packages/ti/mcu/msp430//include" $<
	
objs\WDTplus_init.obj: WDTplus_init.c
	@echo cl430 $< ...
	$(CC) $(CCOPTS) -I "C:/TI/grace_1_10_00_17/packages"  -I "C:/TI/grace_1_10_00_17/packages/ti/mcu/msp430//include" $<
	
csl.lib: objs\CSL_init.obj objs\GPIO_init.obj objs\BCSplus_init.obj objs\USCI_B0_init.obj objs\Timer0_A3_init.obj objs\System_init.obj objs\WDTplus_init.obj
	@ echo ar430 $@ $< ...
	$(AR) $@ $^

clean:
	-@$(RM) csl.lib
	-@$(RM) objs\CSL_init.obj
	-@$(RM) objs\GPIO_init.obj
	-@$(RM) objs\BCSplus_init.obj
	-@$(RM) objs\USCI_B0_init.obj
	-@$(RM) objs\Timer0_A3_init.obj
	-@$(RM) objs\System_init.obj
	-@$(RM) objs\WDTplus_init.obj



