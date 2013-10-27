XILINX=		/opt/Xilinx/14.4
ISE=		$(XILINX)/ISE_DS/ISE
XBIN=		$(ISE)/bin/lin64

XST=		${XBIN}/xst
NGDBUILD=	${XBIN}/ngdbuild
MAP=		${XBIN}/map
PAR=		${XBIN}/par
BITGEN=		${XBIN}/bitgen
TRCE=		${XBIN}/trce
DATA2MEM=	${XBIN}/data2mem

XSIM=		${ISE}/verilog/src/unisims

INTSTYLE=	-intstyle ise

.PHONY:		all clean xstest testbench backup info gtk 

.SUFFIXES:	.lso .ucf .v .ngc .ngd .pcf .par .bit .ngm

RTL=		rtl/leds.v

TB=		testbench/tb.v

BOARD=		xula2

ifeq ($(BOARD), xula)
TARGET=		XC3S200A-VQ100-4
TOP=		fpga_top
UCF=		s3a/leds.ucf
endif

ifeq ($(BOARD), xula2)
TARGET=		XC6SLX25-FTG256-2
TOP=		fpga_top
UCF=		s6/leds.ucf
endif

PROJ=		leds

all:		fpga.bit

fpga.bit:	xst/fpga.bit
ifdef BMM
		${DATA2MEM} -bm ${BMM}_bd.bmm -bd src/build/elf/$(PROJ).elf -bt xst/fpga.bit -o b fpga.bit
else
		cp xst/fpga.bit .
endif
		rm -rf *.xrpt *.lst *.xml *.html *.lso xlnx_auto_0_xdb _xmsgs xst/tmp

xst/fpga.bit:	xst/fpga.twr
ifeq ($(BOARD), xula2)
		${BITGEN} -w					\
			-g StartupClk:JtagClk			\
			-g TckPin:PullNone			\
			-g DonePin:PullUp			\
			-g UnusedPin:PullUp			\
			xst/fpga.ncd
else
		${BITGEN} -w -g StartupClk:JtagClk xst/fpga.ncd
endif

xst/fpga.twr:	xst/fpga.par
		${TRCE} -v 12 -fastpaths ${INTSTYLE} -o xst/fpga.twr xst/fpga.ncd xst/fpga.pcf -ucf ${UCF}

#		${TRCE} ${INTSTYLE} -e 10 -s 4 -xml xst/fpga xst/fpga.ncd -o xst/fpga.twr xst/fpga.pcf -ucf ${UCF}

xst/fpga.par:	xst/fpga.ncd
		${PAR} -ol high -w xst/fpga.ncd xst/fpga.ncd


xst/fpga.ncd:	xst/fpga.ngd
		${MAP} -w  -p ${TARGET} -o xst/fpga.ncd xst/fpga.ngd

xst/fpga.ngd:	xst/fpga.ngc
		${NGDBUILD} -aul -uc ${UCF} xst/fpga.ngc xst/fpga.ngd

xst/fpga.ngc:	xst/fpga.xst
		mkdir -p xst/projnav.tmp
		${XST} ${INTSTYLE} -ifn xst/fpga.xst -ofn xst/fpga.srp

xst/fpga.xst:	xst/fpga.prj
		@echo "run"				>  xst/fpga.xst
		@echo "-ifn xst/fpga.prj"		>> xst/fpga.xst
		@echo "-ifmt mixed"			>> xst/fpga.xst
		@echo "-top ${TOP}"			>> xst/fpga.xst
		@echo "-ofn xst/fpga.ngc"		>> xst/fpga.xst
		@echo "-ofmt NGC"			>> xst/fpga.xst
		@echo "-p ${TARGET}"			>> xst/fpga.xst
		@echo "-opt_mode speed"			>> xst/fpga.xst
		@echo "-opt_level 2"			>> xst/fpga.xst
		@echo "-tmpdir xst/tmp"			>> xst/fpga.xst
		@echo "-xsthdpdir xst/tmp"		>> xst/fpga.xst
		@echo "-define { $(XST_DEFINES) )}"	>> xst/fpga.xst

xst/fpga.prj:	${RTL} ${UCF}
		mkdir -p xst
		rm -f xst/fpga.prj
		touch xst/fpga.prj
		@for f in ${RTL}; do echo "verilog work $$f" >> xst/fpga.prj; done

xst/impact.cmd:
		mkdir -p xst
		rm -f xst/impact.cmd
		@echo "setMode -bs"			>  xst/impact.cmd
		@echo "setCable -port auto"		>> xst/impact.cmd
		@echo "identify"			>> xst/impact.cmd
		@echo "assignFile -p 1 -file fpga.bit"	>> xst/impact.cmd
		@echo "Program -p 1 -onlyFpga "		>> xst/impact.cmd
		@echo "quit"				>> xst/impact.cmd

xsload:		fpga.bit
		xsload.py --fpga fpga.bit

info:
		@echo "TARGET : " ${TARGET}
		@echo "RTL    : " ${RTL}
		@echo "TOP    : " ${TOP}
		@echo "BMM    : " ${BMM}
		@echo "UCF    : " ${UCF}
		@echo "XBIN   : " ${XBIN}

gtk:		testbench/tb
		cd testbench; ./tb
		gtkwave testbench/dump.vcd testbench/dump.sav

testbench/tb:	$(TB) $(RTL)
		iverilog -o testbench/tb -y lib			\
			-y $(ISE)/verilog/src/unisims	\
			$(TB) $(RTL)

clean:
		rm -f *~ */*~ tb *.lso *.xrpt *.lst *.xml *.bit *.vcd
		rm -rf xst _xmsgs xlnx_auto_0_xdb *.html 
		rm -f testbench/tb

backup:
		mkdir -p /usr/local/backups/xess/LedsTest
		tar -czf /usr/local/backups/xess/LedsTest/leds-`date +%Y-%m-%d-%H-%M`.tar.gz s3a s6 rtl testbench README Makefile
