#
_XDCBUILDCOUNT = 
ifneq (,$(findstring path,$(_USEXDCENV_)))
override XDCPATH = C:/TI/grace_1_10_00_17/packages;K:/MYDOCU~1/WorkspaceCCS5/ServoI2C/.config
override XDCROOT = C:/TI/xdctools_3_22_04_46
override XDCBUILDCFG = ./config.bld
endif
ifneq (,$(findstring args,$(_USEXDCENV_)))
override XDCARGS = 
override XDCTARGETS = 
endif
#
ifeq (0,1)
PKGPATH = C:/TI/grace_1_10_00_17/packages;K:/MYDOCU~1/WorkspaceCCS5/ServoI2C/.config;C:/TI/xdctools_3_22_04_46/packages;..
HOSTOS = Windows
endif
