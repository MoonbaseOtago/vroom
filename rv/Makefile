SRC = \
	chip.sv mi.sv \
	cpu.sv \
	decode.sv \
	rename.sv \
	commit.sv \
	alu.sv \
	shift.sv \
	branch.sv \
	mul.sv \
	alu_ctrl.sv \
	csr.sv \
	pc.sv \
	bpred.sv \
	dtlb.sv \
	itlb.sv \
	ls.sv \
	dc1.sv \
	ic1.sv \
	fetch.sv \
	tlbf.sv \
	tc2.sv \
	pmap.sv \
	ioi.sv \
	rvtimer.sv \
	clic.sv \
	plic.sv \
	boot0.sv \
	boot1.sv \
	dtbrom.sv \
	rviodtb.sv \
	rvsd.sv \
	rvgpio.sv

INCLUDES = cache_protocol.si  pred_context.si lstypes.si

DRAM = mmem.sv 

SYNTH = \
	synth/vsram.v

#NALU3_1 = +define+NALU3
#NALU3_2 = -DNALU3
NALU3_1 = 
NALU3_2 = 
NSTORE2_1 = 
NSTORE2_2 = 
#NSTORE2_1 =
#NSTORE2_2 =
OPT_FLAG_1 = $(NALU3_1) $(NSTORE2_1)
OPT_FLAG_2 = $(NALU3_2) $(NSTORE2_2)
XTEST = aws-design/design/cl_template.sv synth/vsram.v synth/mmem.sv xcels.sv
XSYNTH1 = +define+VSYNTH  +define+VS2 +incdir+aws-design/design +incdir+aws-fpga/hdk/common/shell_v04261818/design/interfaces +define+VVV  $(OPT_FLAG_1)
XSYNTH2 = -DPSYNTH -DVSYNTH -DVS2 -Iaws-design/design -Iaws-fpga/hdk/common/shell_v04261818/design/interfaces -DVVV $(OPT_FLAG_2)

FPU = fp_add.sv fp_mul.sv fp.sv 
FPINC = mkf1.inc mkf2.inc mkf3.inc mkf4.inc mkf6.inc


VSYNTH1 = +define+VSYNTH +define+VSYNTH2 $(OPT_FLAG_1)
VSYNTH2 = -D VSYNTH $(OPT_FLAG_2)

UART = rvuart.sv uart/raminfr.v uart/uart_receiver.v uart/uart_regs.v uart/uart_rfifo.v  uart/uart_sync_flops.v  uart/uart_tfifo.v uart/uart_top.v uart/uart_transmitter.v  uart/uart_wb.v
UART_DEF1 = +incdir+uart 
UART_DEF2 = -Iuart 

VERILATOR= /usr/local/bin/verilator --error-limit 10 -j 16 --timescale-override "1ns/1ns"

MX = mkinc4.inc mkinc8.inc mkinc16.inc
MX2 = mk2_4.inc mk2_8.inc mk2_16.inc
MX3 = mk3_4.inc mk3_8.inc mk3_16.inc
MX4 = mk4_16.inc mk4_32.inc mk4_64.inc
MX5 = mk5_4.inc mk5_8.inc mk5_16.inc
MX6 = mk6_64.inc 
MX7 = mk7_4_4_32.inc mk7_8_4_32.inc mk7_16_4_32.inc mk7_4_8_32.inc mk7_8_8_32.inc mk7_16_8_32.inc
MX8 = mk8_4.inc mk8_8.inc mk8_16.inc
MX9 = mk9_4.inc mk9_8.inc mk9_16.inc
MX10 = mk10_2.inc mk10_4.inc mk10_8.inc mk10_16.inc
MX11 = mk11_4_2.inc mk11_8_2.inc mk11_16_2.inc mk11_32_2.inc mk11_64_2.inc mk11_4_3.inc mk11_8_3.inc mk11_16_3.inc mk11_32_3.inc mk11_64_3.inc mk11_32_4.inc
MX12 = mk12_16.inc mk12_32.inc mk12_64.inc
MX13 = mk13_8_2_1.inc mk13_16_2_1.inc mk13_32_2_1.inc mk13_8_2_2.inc mk13_16_2_2.inc mk13_32_2_2.inc mk13_16_4_4.inc mk13_32_4_4.inc 
MX14 = mk14_6_4_4_1.inc mk14_4_2_2_1.inc
MX15 = mk15_10_2.inc mk15_11_2.inc mk15_12_2.inc mk15_15_2.inc mk15_14_2.inc
MX16 = mk16_8.inc mk16_16.inc mk16_32.inc
MX17 = mk17_1_6.inc mk17_1_5.inc  mk17_1_4.inc
MX19 = mk19_64.inc 
MX20 = mk20_32_8.inc mk20_32_16.inc
MX21 = mk21_32_6_4_4_16.inc mk21_32_4_2_2_16.inc mk21_32_6_4_4_32.inc mk21_32_4_2_2_32.inc
#MXREG = rfile_13_3_6_2_8_32_1.sv 
#MXREG = rfile_15_3_7_2_8_32_1.sv
MXREG = rfile_19_3_8_2_8_32_2.sv
MXREGX= rfile_15_3_6_2_8_32_2.sv
FMXREG = rfile_14_3_7_2_8_32_4.sv # rfile_16_3_8_2_8_32_4.sv
#MXREG = rfile_16_3_7_2_8_32.sv
MXREGINC =  rfile_16_3_7_2_4_32_1.inc rfile_16_3_7_2_8_32_1.inc rfile_13_3_6_2_4_32_1.inc rfile_13_3_6_2_8_32_1.inc \
	    rfile_16_3_7_2_4_32_4.inc rfile_16_3_7_2_8_32_4.inc rfile_13_3_6_2_4_32_4.inc rfile_13_3_6_2_8_32_4.inc \
	   rfile_14_3_7_2_4_32_4.inc rfile_14_3_7_2_4_32_1.inc rfile_14_3_7_2_8_32_4.inc \
	  rfile_15_3_7_2_4_32_1.inc rfile_15_3_7_2_8_32_1.inc rfile_15_3_6_2_8_32_2.inc rfile_15_3_6_2_4_32_2.inc \
		rfile_19_3_8_2_8_32_2.inc 
		
MXCTRL = alu_ctrl_hdr_4_1_32_2_1_1_1_0.inc  alu_ctrl_core_4_1_32_2_1_1_1_0.inc  alu_ctrl_inst_4_1_32_2_1_1_1_0.inc   alu_ctrl_hdr_4_1_32_3_1_1_1_0.inc \
	alu_ctrl_hdr_4_1_32_2_1_1_1_1.inc alu_ctrl_core_4_1_32_2_1_1_1_1.inc alu_ctrl_inst_4_1_32_2_1_1_1_1.inc alu_ctrl_inst_4_1_32_3_1_1_1_0.inc alu_ctrl_core_4_1_32_3_1_1_1_0.inc 
MXA = $(MX) $(MX2) $(MX3) $(MX4) $(MX5) $(MX6) $(MX7) $(MX8) $(MX9) $(MX10) $(MX11) $(MX12) $(MX13) $(MX14) $(MX15) $(MX16) $(MX17) $(MX19) $(MX20) $(MX21) $(MXREG) $(MXREGINC) $(MXCTRL) $(MXREGX)

all:	svv

# note icarus verilog is no longer viable as it doesn't support interfaces
sv:	test.sv $(SRC) $(MXA) $(UART) $(SYNTH) $(DRAM) $(INCLUDES)
	iverilog -g 2012 -D SIMV  $(VSYNTH2) -o sv test.sv $(SRC) $(DRAM) $(MXREG)  $(UART_DEF2) $(UART)  $(SYNTH) $(OPT_FLAG_2)
	iverilog -g 2012 -D SIMV $(VSYNTH2) -D SIMD  -o svd test.sv $(SRC) $(DRAM) $(MXREG) $(UART_DEF2)  $(UART) $(SYNTH) $(OPT_FLAG_2)

svb:	test.sv $(SRC) $(MXA) $(UART) $(SYNTH) $(DRAM) $(INCLUDES)
	iverilog -g 2005-sv -D SIMV  $(VSYNTH2) -D B -o svb test.sv $(SRC) $(DRAM) $(MXREG)  $(UART_DEF2) $(UART)  $(SYNTH) $(OPT_FLAG_2)
	iverilog -g 2005-sv -D SIMV $(VSYNTH2) -D SIMD -D B -o svdb test.sv $(SRC) $(DRAM) $(MXREG) $(UART_DEF2)  $(UART) $(SYNTH) $(OPT_FLAG_2)

svf:	test.sv $(SRC) $(MXA) $(UART) $(SYNTH) $(DRAM) $(FPINC) $(FPU) $(FMXREG)  $(INCLUDES)
	iverilog -g 2005-sv -D SIMV  $(VSYNTH2) -D FP -o svf test.sv $(SRC) $(DRAM) $(FMXREG)  $(UART_DEF2) $(UART)  $(SYNTH) $(FPU) $(OPT_FLAG_2)
	iverilog -g 2005-sv -D SIMV $(VSYNTH2) -D SIMD -D FP -o svdf test.sv $(SRC) $(DRAM) $(FMXREG) $(UART_DEF2)  $(UART) $(SYNTH) $(FPU) $(OPT_FLAG_2)

svx:	test.sv $(SRC) $(MXA) $(UART)  $(SYNTH)  $(DRAM) $(INCLUDES)
	iverilog -g 2005-sv -D SIMV $(VSYNTH2)  -o svx test.sv $(SRC) $(DRAM) $(MXREG) $(UART_DEF2) $(UART) $(SYNTH) -pfileline=1  $(OPT_FLAG_2)

svv:	obj_dir/svv
svv-lint:	obj_dir/svv-lint

obj_dir/svv-lint:	$(SRC) $(MXA) $(UART) testbench.cpp $(SYNTH)  $(DRAM) $(INCLUDES)
	$(VERILATOR) -cc  --threads 7  --top-module chip --autoflush -CFLAGS "-g" -LDFLAGS "-g" +1800-2017ext+sv -o svv-lint  +define+SIMV +define+SIMD $(VSYNTH1) $(SRC) $(DRAM) $(MXREG)  $(UART_DEF1)  $(UART)  $(SYNTH) $(OPT_FLAG_1) --assert --clk clk  --trace  -sv --compiler gcc -exe testbench.cpp

obj_dir/svv:	$(SRC) $(MXA) $(UART) testbench.cpp $(SYNTH)  $(DRAM) $(INCLUDES)
	$(VERILATOR) -cc  --threads 7  --top-module chip --autoflush -CFLAGS "-g" -LDFLAGS "-g" -Wno-lint +1800-2017ext+sv -o svv  +define+SIMV +define+SIMD $(VSYNTH1) $(SRC) $(DRAM) $(MXREG)  $(UART_DEF1)  $(UART)  $(SYNTH) $(OPT_FLAG_1) --assert --clk clk  --trace  -sv --compiler gcc -exe testbench.cpp
	make -j 16  -C obj_dir -f Vchip.mk svv

fvv:	fobj_dir/fvv
fobj_dir/fvv:	$(SRC) $(MXA) $(UART) testbench.cpp $(SYNTH)  $(DRAM) $(FPINC) $(FPU) $(FMXREG)  $(INCLUDES)
	$(VERILATOR) -cc  --threads 7 --top-module chip --autoflush -CFLAGS "-g" -LDFLAGS "-g" -Wno-lint +1800-2017ext+sv -o fvv  +define+SIMV +define+SIMD +define+FP $(VSYNTH1) $(SRC) $(DRAM) $(FMXREG)  $(UART_DEF1)  $(UART)  $(SYNTH) $(OPT_FLAG_1) $(FPU) --assert --clk clk  --trace  -sv --compiler gcc --Mdir fobj_dir -exe testbench.cpp
	make -j 16 -C fobj_dir -f Vchip.mk fvv

svl:	$(SRC) $(MXA) $(UART) $(SYNTH) $(DRAM) $(INCLUDES)
	$(VERILATOR) -lint-only +1800-2005ext+sv --top-module chip $(VSYNTH1) -o svv $(SRC) $(DRAM) $(MXREG) $(UART_DEF1)  $(UART) $(SYNTH) $(OPT_FLAG_1)

tv:	aws-test/test.sv $(SRC) $(MXA) $(UART)  $(SYNTH) $(XTEST) aws-test/test_devices.sv $(INCLUDES)
	iverilog -g 2005-sv -D SIMV  $(XSYNTH2) -o tv aws-test/test.sv aws-test/test_devices.sv $(SRC) $(XTEST) $(MXREG)  $(UART_DEF2) $(UART)  $(OPT_FLAG_2)
	iverilog -g 2005-sv -D SIMV  $(XSYNTH2) -o tvd -D SIMD aws-test/test.sv aws-test/test_devices.sv $(SRC) $(XTEST) $(MXREG)  $(UART_DEF2) $(UART)  $(OPT_FLAG_2)

tvv:	obj_dir/tvv 
obj_dir/tvv:	$(SRC) $(MXA) $(UART) aws-test/xtestbench.cpp $(SYNTH)  $(XTEST) aws-test/test.sv aws-test/test_devices.sv $(INCLUDES)
	$(VERILATOR) -cc  --threads 7  --top-module test --autoflush -CFLAGS "-g" -LDFLAGS "-g" $(OPT_FLAG_1) -Wno-lint +1800-2017ext+sv -o tvv  +define+AWS_VERILATOR  +define+VSYNTH2 +define+SIMV +define+SIMD aws-test/test.sv aws-test/test_devices.sv $(XSYNTH1) $(SRC) $(MXREG)  $(UART_DEF1)  $(UART) $(XTEST) --assert --clk clk_main_a0  --trace  -sv --compiler gcc --Mdir awsobj_dir -exe aws-test/xtestbench.cpp
	make -j 16 -C awsobj_dir -f Vtest.mk tvv

alu_ctrl_hdr_4_1_32_2_1_1_1_0.inc:	mkctrl 
	./mkctrl -hdr 4 1 32 2 1 1 1 0 >$@
alu_ctrl_core_4_1_32_2_1_1_1_0.inc:	mkctrl
	./mkctrl -core 4 1 32 2 1 1 1 0 >$@
alu_ctrl_inst_4_1_32_2_1_1_1_0.inc:	mkctrl
	./mkctrl -inst 4 1 32 2 1 1 1 0 >$@

alu_ctrl_hdr_4_1_32_3_1_1_1_0.inc:	mkctrl 
	./mkctrl -hdr 4 1 32 3 1 1 1 0 >$@
alu_ctrl_core_4_1_32_3_1_1_1_0.inc:	mkctrl
	./mkctrl -core 4 1 32 3 1 1 1 0 >$@
alu_ctrl_inst_4_1_32_3_1_1_1_0.inc:	mkctrl
	./mkctrl -inst 4 1 32 3 1 1 1 0 >$@

alu_ctrl_hdr_4_1_32_2_1_1_1_1.inc:	mkctrl 
	./mkctrl -hdr 4 1 32 2 1 1 1 1 >$@
alu_ctrl_core_4_1_32_2_1_1_1_1.inc:	mkctrl
	./mkctrl -core 4 1 32 2 1 1 1 1 >$@
alu_ctrl_inst_4_1_32_2_1_1_1_1.inc:	mkctrl
	./mkctrl -inst 4 1 32 2 1 1 1 1 >$@
alu_ctrl_hdr_4_1_32_2_1_1_1_1_1.inc:	mkctrl 
	./mkctrl -hdr 4 1 32 2 1 1 1 1 >$@

rfile_13_3_6_2_4_32_4.sv:	rfile
	./rfile 13 3 6 2 4 32 4 >$@
rfile_13_3_6_2_8_32_4.sv:	rfile
	./rfile 13 3 6 2 8 32 4 >$@
rfile_13_3_6_2_4_32_4.inc:	rfile
	./rfile -inc 13 3 6 2 4 32 4 >$@
rfile_13_3_6_2_8_32_4.inc:	rfile
	./rfile -inc 13 3 6 2 8 32 4 >$@
rfile_12_3_5_2_4_32_4.sv:	rfile
	./rfile 12 3 5 2 4 32 4 >$@
rfile_12_3_5_2_8_32_4.sv:	rfile
	./rfile 12 3 5 2 8 32 4 >$@
rfile_12_3_5_2_4_32_4.inc:	rfile
	./rfile -inc 12 3 5 2 4 32 4 >$@
rfile_12_3_5_2_8_32_4.inc:	rfile
	./rfile -inc 12 3 5 2 8 32 4 >$@
rfile_14_3_7_2_4_32_4.sv:	rfile
	./rfile 14 3 7 2 4 32 4 >$@
rfile_14_3_7_2_8_32_4.sv:	rfile
	./rfile 14 3 7 2 8 32 4 >$@
rfile_14_3_7_2_4_32_4.inc:	rfile
	./rfile -inc 14 3 7 2 4 32 4 >$@
rfile_14_3_7_2_8_32_4.inc:	rfile
	./rfile -inc 14 3 7 2 8 32 4 >$@
rfile_16_3_7_2_4_32_4.sv:	rfile
	./rfile 16 3 7 2 4 32 4 >$@
rfile_16_3_7_2_8_32_4.sv:	rfile
	./rfile 16 3 7 2 8 32 4 >$@
rfile_16_3_7_2_4_32_4.inc:	rfile
	./rfile -inc 16 3 7 2 4 32 4 >$@
rfile_16_3_7_2_8_32_4.inc:	rfile
	./rfile -inc 16 3 7 2 8 32 4 >$@

rfile_13_3_6_2_4_32_1.sv:	rfile
	./rfile 13 3 6 2 4 32 1 >$@
rfile_15_3_6_2_4_32_2.sv:	rfile
	./rfile 15 3 6 2 4 32 2 >$@
rfile_13_3_6_2_8_32_1.sv:	rfile
	./rfile 13 3 6 2 8 32 1 >$@
rfile_15_3_6_2_8_32_2.sv:	rfile
	./rfile 15 3 6 2 8 32 2 >$@
rfile_13_3_6_2_8_32_3.sv:	rfile
	./rfile 13 3 6 2 8 32 3 >$@
rfile_15_3_6_2_4_32_2.inc:	rfile
	./rfile -inc 15 3 6 2 4 32 2 >$@
rfile_13_3_6_2_4_32_1.inc:	rfile
	./rfile -inc 13 3 6 2 4 32 1 >$@
rfile_13_3_6_2_8_32_1.inc:	rfile
	./rfile -inc 13 3 6 2 8 32 1 >$@
rfile_15_3_6_2_8_32_2.inc:	rfile
	./rfile -inc 15 3 6 2 8 32 2 >$@
rfile_13_3_6_2_8_32_3.inc:	rfile
	./rfile -inc 13 3 6 2 8 32 3 >$@

rfile_15_3_7_2_4_32_1.sv:	rfile
	./rfile 15 3 7 2 4 32 1 >$@
rfile_15_3_7_2_4_32_1.inc:	rfile
	./rfile -inc 15 3 7 2 8 32 1 >$@
rfile_15_3_7_2_8_32_1.sv:	rfile
	./rfile 15 3 7 2 8 32 1 >$@
rfile_15_3_7_2_8_32_1.inc:	rfile
	./rfile -inc 15 3 7 2 8 32 1 >$@

rfile_19_3_8_2_8_32_2.sv:	rfile
	./rfile 19 3 8 2 8 32 2 >$@
rfile_19_3_8_2_8_32_2.inc:	rfile
	./rfile -inc 19 3 8 2 8 32 2 >$@

rfile_12_3_5_2_4_32_1.sv:	rfile
	./rfile 12 3 5 2 4 32 1 >$@
rfile_12_3_5_2_8_32_1.sv:	rfile
	./rfile 12 3 5 2 8 32 1 >$@
rfile_12_3_5_2_4_32_1.inc:	rfile
	./rfile -inc 12 3 5 2 4 32 1 >$@
rfile_12_3_5_2_8_32_1.inc:	rfile
	./rfile -inc 12 3 5 2 8 32 1 >$@
rfile_14_3_7_2_4_32_1.sv:	rfile
	./rfile 14 3 7 2 4 32 1 >$@
rfile_14_3_7_2_8_32_1.sv:	rfile
	./rfile 14 3 7 2 8 32 1 >$@
rfile_14_3_7_2_4_32_1.inc:	rfile
	./rfile -inc 14 3 7 2 4 32 1 >$@
rfile_14_3_7_2_8_32_1.inc:	rfile
	./rfile -inc 14 3 7 2 8 32 1 >$@
rfile_16_3_7_2_4_32_1.sv:	rfile
	./rfile 16 3 7 2 4 32 1 >$@
rfile_16_3_7_2_8_32_1.sv:	rfile
	./rfile 16 3 7 2 8 32 1 >$@
rfile_16_3_7_2_4_32_1.inc:	rfile
	./rfile -inc 16 3 7 2 4 32 1 >$@
rfile_16_3_7_2_8_32_1.inc:	rfile
	./rfile -inc 16 3 7 2 8 32 1 >$@

rfile:	rfile.c
	gcc -o rfile rfile.c

mkenc:	mkenc.c
	gcc -o mkenc mkenc.c


mk2:	mk2.c
	gcc -o mk2 mk2.c

mk2_4.inc: mk2
	./mk2 4 >mk2_4.inc
mk2_8.inc: mk2
	./mk2 8 >mk2_8.inc
mk2_16.inc: mk2
	./mk2 16 >mk2_16.inc

mkinc4.inc: mkenc
	./mkenc 4 >mkinc4.inc

mkinc8.inc: mkenc
	./mkenc 8 >mkinc8.inc

mkinc16.inc: mkenc
	./mkenc 16 >mkinc16.inc

mk3:	mk3.c
	gcc -o mk3 mk3.c

mk3_4.inc: mk3
	./mk3 4 >mk3_4.inc
mk3_8.inc: mk3
	./mk3 8 >mk3_8.inc
mk3_16.inc: mk3
	./mk3 16 >mk3_16.inc


mk4:	mk4.c
	gcc -o mk4 mk4.c

mk4_16.inc: mk4
	./mk4 16 >mk4_16.inc
mk4_32.inc: mk4
	./mk4 32 >mk4_32.inc
mk4_64.inc: mk4
	./mk4 64 >mk4_64.inc

mk5:	mk5.c
	gcc -o mk5 mk5.c

mk5_4.inc: mk5
	./mk5 4 >mk5_4.inc
mk5_8.inc: mk5
	./mk5 8 >mk5_8.inc
mk5_16.inc: mk5
	./mk5 16 >mk5_16.inc

mk6:	mk6.c
	gcc -o mk6 mk6.c

mk6_64.inc: mk6
	./mk6 64 >mk6_64.inc

mk7:	mk7.c
	gcc -o mk7 mk7.c
mk7_4_4_32.inc: mk7
	./mk7 4 4 32 >mk7_4_4_32.inc
mk7_8_4_32.inc: mk7
	./mk7 8 4 32 >mk7_8_4_32.inc
mk7_16_4_32.inc: mk7
	./mk7 16 4 32 >mk7_16_4_32.inc
mk7_4_8_32.inc: mk7
	./mk7 4 8 32 >mk7_4_8_32.inc
mk7_8_8_32.inc: mk7
	./mk7 8 8 32 >mk7_8_8_32.inc
mk7_16_8_32.inc: mk7
	./mk7 16 8 32 >mk7_16_8_32.inc

mk8:	mk8.c
	gcc -o $@ mk8.c
mk8_4.inc: mk8
	./mk8 4 >$@
mk8_8.inc: mk8
	./mk8 8 >$@
mk8_16.inc: mk8
	./mk8 16 >$@

mk9:	mk9.c
	gcc -o $@ mk9.c
mk9_4.inc: mk9
	./mk9 4 >$@
mk9_8.inc: mk9
	./mk9 8 >$@
mk9_16.inc: mk9
	./mk9 16 >$@

mk10:	mk10.c
	gcc -o $@ mk10.c
mk10_2.inc: mk10
	./mk10 2 >$@
mk10_4.inc: mk10
	./mk10 4 >$@
mk10_8.inc: mk10
	./mk10 8 >$@
mk10_16.inc: mk10
	./mk10 16 >$@

mk11:	mk11.c
	gcc -o $@ mk11.c
mk11_4_3.inc: mk11
	./mk11 4 3 >$@
mk11_8_3.inc: mk11
	./mk11 8 3 >$@
mk11_16_3.inc: mk11
	./mk11 16 3 >$@
mk11_32_3.inc: mk11
	./mk11 32 3 >$@
mk11_32_4.inc: mk11
	./mk11 32 4 >$@
mk11_64_3.inc: mk11
	./mk11 64 3 >$@
mk11_4_2.inc: mk11
	./mk11 4 2 >$@
mk11_8_2.inc: mk11
	./mk11 8 2 >$@
mk11_16_2.inc: mk11
	./mk11 16 2 >$@
mk11_32_2.inc: mk11
	./mk11 32 2 >$@
mk11_64_2.inc: mk11
	./mk11 64 2 >$@

mk12:	mk12.c
	gcc -o mk12 mk12.c

mk12_16.inc: mk12
	./mk12 16 >mk12_16.inc
mk12_32.inc: mk12
	./mk12 32 >mk12_32.inc
mk12_64.inc: mk12
	./mk12 64 >mk12_64.inc

mk13:	mk13.c
	gcc -g -o mk13 mk13.c
mk13_8_2_1.inc: mk13
	./mk13 8 2 1 >$@
mk13_16_2_1.inc: mk13
	./mk13 16 2 1 >$@
mk13_32_2_1.inc: mk13
	./mk13 32 2 1 >$@
mk13_8_2_2.inc: mk13
	./mk13 8 2 2 >$@
mk13_16_2_2.inc: mk13
	./mk13 16 2 2 >$@
mk13_32_2_2.inc: mk13
	./mk13 32 2 2 >$@
mk13_16_4_4.inc: mk13
	./mk13 16 4 4 >$@
mk13_32_4_4.inc: mk13
	./mk13 32 4 4 >$@

mk14:	mk14.c
	gcc -o mk14 mk14.c
mk14_6_4_4_1.inc: mk14
	./mk14 6 4 4 1 >$@
mk14_4_2_2_1.inc: mk14
	./mk14 4 2 2 1 >$@

mk15:	mk15.c
	gcc -o mk15 mk15.c
mk15_10_2.inc: mk15
	./mk15 10 2 >$@
mk15_11_2.inc: mk15
	./mk15 11 2 >$@
mk15_12_2.inc: mk15
	./mk15 12 2 >$@
mk15_14_2.inc: mk15
	./mk15 14 2 >$@
mk15_15_2.inc: mk15
	./mk15 15 2 >$@

mk16:	mk16.c
	gcc -o mk16 mk16.c
mk16_8.inc: mk16
	./mk16 8 >$@
mk16_16.inc: mk16
	./mk16 16 >$@
mk16_32.inc: mk16
	./mk16 32 >$@

mk17:	mk17.c
	gcc -o mk17 mk17.c
mk17_1_4.inc: mk17
	./mk17 1 4 >$@
mk17_1_5.inc: mk17
	./mk17 1 5 >$@
mk17_1_6.inc: mk17
	./mk17 1 6 >$@

mk18:	mk18.c
	gcc -o mk18 mk18.c
#xcels.sv: mk18
#	./mk18  >$@


mk20:	mk20.c
	gcc -o mk20 mk20.c

mk20_32_8.inc:	mk20
	./mk20 32 8 >mk20_32_8.inc

mk20_32_16.inc:	mk20
	./mk20 32 16 >mk20_32_16.inc

mk19:	mk19.c
	gcc -o mk19 mk19.c

mk19_64.inc: mk19
	./mk19 64 >mk19_64.inc

mk21:	mk21.c
	gcc -o mk21 mk21.c

mk21_32_6_4_4_16.inc:	mk21
	./mk21 32 6 4 4 16  >$@

mk21_32_4_2_2_16.inc:	mk21
	./mk21 32 4 2 2 16  >$@

mk21_32_6_4_4_32.inc:	mk21
	./mk21 32 6 4 4 32  >$@

mk21_32_4_2_2_32.inc:	mk21
	./mk21 32 4 2 2 32  >$@


mkf1:	mkf1.c
	gcc -o mkf1 mkf1.c
mkf1.inc:	mkf1
	./mkf1 >$@

mkf2:	mkf2.c
	gcc -o mkf2 mkf2.c
mkf2.inc:	mkf2
	./mkf2 >$@

mkf3:	mkf3.c
	gcc -o mkf3 mkf3.c
mkf3.inc:	mkf3
	./mkf3 >$@

mkf4:	mkf4.c
	gcc -o mkf4 mkf4.c
mkf4.inc:	mkf4
	./mkf4 >$@

mkf6:	mkf6.c
	gcc -o mkf6 mkf6.c
mkf6.inc:	mkf6
	./mkf6 >$@

fp_add_test_32.txt:	timesoftfloat32
	./timesoftfloat32 -nearesteven float32_add > fp_add_test_32.txt
	./timesoftfloat32 -nearesteven float32_sub >> fp_add_test_32.txt
	./timesoftfloat32 -tozero float32_add >> fp_add_test_32.txt
	./timesoftfloat32 -tozero float32_sub >> fp_add_test_32.txt
	./timesoftfloat32 -up float32_add >> fp_add_test_32.txt
	./timesoftfloat32 -up float32_sub >> fp_add_test_32.txt
	./timesoftfloat32 -down float32_add >> fp_add_test_32.txt
	./timesoftfloat32 -down float32_sub >> fp_add_test_32.txt

fp_add_test_64.txt:	timesoftfloat32
	./timesoftfloat32 -nearesteven float64_add > fp_add_test_64.txt
	./timesoftfloat32 -nearesteven float64_sub >> fp_add_test_64.txt
	./timesoftfloat32 -tozero float64_add >> fp_add_test_64.txt
	./timesoftfloat32 -tozero float64_sub >> fp_add_test_64.txt
	./timesoftfloat32 -up float64_add >> fp_add_test_64.txt
	./timesoftfloat32 -up float64_sub >> fp_add_test_64.txt
	./timesoftfloat32 -down float64_add >> fp_add_test_64.txt
	./timesoftfloat32 -down float64_sub >> fp_add_test_64.txt

fp_mul_test_32.txt:     timesoftfloat32
	./timesoftfloat32 -nearesteven float32_mul > fp_mul_test_32.txt
	./timesoftfloat32 -tozero float32_mul >> fp_mul_test_32.txt
	./timesoftfloat32 -up float32_mul >> fp_mul_test_32.txt
	./timesoftfloat32 -down float32_mul >> fp_mul_test_32.txt

fp_mul_test_64.txt:     timesoftfloat32
	./timesoftfloat32 -nearesteven float64_mul > fp_mul_test_64.txt
	./timesoftfloat32 -tozero float64_mul >> fp_mul_test_64.txt
	./timesoftfloat32 -up float64_mul >> fp_mul_test_64.txt
	./timesoftfloat32 -down float64_mul >> fp_mul_test_64.txt

#	./timesoftfloat32 -nearesteven float32_div >> testcases.txt 
#	./timesoftfloat32 -nearesteven float32_sqrt >> testcases.txt 
#	./timesoftfloat32 -tozero float32_div >> testcases.txt 
#	./timesoftfloat32 -tozero float32_sqrt >> testcases.txt 
#	./timesoftfloat32 -up float32_div >> testcases.txt 
#	./timesoftfloat32 -up float32_sqrt >> testcases.txt 
#	./timesoftfloat32 -down float32_div >> testcases.txt 
#	./timesoftfloat32 -down float32_sqrt >> testcases.txt



cvtbin:	cvtbin.c
	gcc -o cvtbin cvtbin.c

mk: x.bin

boot0.sv:	boot0.s cvtbin
	riscv64-linux-gnu-gcc -c boot0.s -march=rv64imac
	riscv64-linux-gnu-ld -N -o boot0.elf -e start -Ttext-segment=0 -N -static boot0.o -Tlink.ld
	riscv64-linux-gnu-objcopy -O binary boot0.elf boot0.bin
	./cvtbin boot0.bin bootrom0 128 >boot0.sv

boot1.sv:	boot1.s cvtbin
	riscv64-linux-gnu-gcc -c boot1.s -march=rv64imac
	riscv64-linux-gnu-ld -N -o boot1.elf -e start -Ttext-segment=0 -N -static boot1.o -Tlink.ld
	riscv64-linux-gnu-objcopy -O binary boot1.elf boot1.bin
	./cvtbin boot1.bin bootrom1 128 >boot1.sv

dtbrom.sv:	sv.dtb cvtbin
	./cvtbin sv.dtb dtbrom 64 >dtbrom.sv

cache_test:	cache.s
	riscv64-linux-gnu-gcc -c cache.s -march=rv64im
	riscv64-linux-gnu-ld -N -o x -e start -Ttext-segment=0 -N -static cache.o -Tlink.ld
	riscv64-linux-gnu-objcopy -O binary x x.bin
	riscv64-linux-gnu-objdump -d x >x.lst


x.bin:	x.s
	riscv64-linux-gnu-gcc -c x.s -march=rv64im
	riscv64-linux-gnu-ld -N -o x -e start -Ttext-segment=0 -N -static x.o -Tlink.ld
	riscv64-linux-gnu-objcopy -O binary x x.bin
	riscv64-linux-gnu-objdump -d x >x.lst

bbl.bin: linux/riscv-pk/build/bbl
	riscv64-linux-gnu-objcopy -O binary linux/riscv-pk/build/bbl bbl.bin
	riscv64-linux-gnu-objdump -d linux/riscv-pk/build/bbl >bbl.lst

opensbi.bin: linux/opensbi-master/build/platform/moonbase/firmware/fw_jump.elf
	riscv64-linux-gnu-objcopy -O binary linux/opensbi-master/build/platform/moonbase/firmware/fw_jump.elf opensbi.bin
	riscv64-linux-gnu-objdump -d linux/opensbi-master/build/platform/moonbase/firmware/fw_jump.elf >opensbi.lst

sv.dtb:	sv.dts
	~/dtc -I dts sv.dts -o sv.dtb

fpt:	testfp.sv fp_add.sv mkf1.inc mkf2.inc fp_mul.sv mkf3.inc
	iverilog testfp.sv fp_add.sv fp_mul.sv -g 2005-sv -o fpt

fpadd32:	fpt fp_add_test_32.txt
	./fpt +s

fpadd64:	fpt fp_add_test_64.txt
	./fpt +d

fpmul32:	fpt fp_mul_test_32.txt
	./fpt +s +m

fpmul64:	fpt fp_mul_test_64.txt
	./fpt +d +m

make_image:	make_image.c
	gcc -o make_image make_image.c

boot_image:	make_image  linux/u-boot/spl/u-boot-spl.bin linux/u-boot/u-boot.itb
	./make_image -o boot_image -a 0 linux/u-boot/spl/u-boot-spl.bin -a 0x200000 linux/u-boot/u-boot.itb 
boot_image2:	make_image  linux/u-boot/spl/u-boot-spl.bin linux/u-boot/u-boot.itb fs.img
	./make_image -o boot_imagex -a 0 linux/u-boot/spl/u-boot-spl.bin -a 0x200000 linux/u-boot/u-boot.itb -f fs.img
fs.img: fs.part linux/linux/vmlinux makefs.sh
	dd if=/dev/zero bs=2M count=1000 > fs.img
	sfdisk fs.img < fs.part
	sh makefs.sh


t:	t.S link.ld
	@riscv64-linux-gnu-gcc -c $@.S -march=rv64imafdc -o $@.o
	@riscv64-linux-gnu-ld -N -e start -Ttext-segment=0 -N -static $@.o -o $@.elf -Tlink.ld
	@riscv64-linux-gnu-objcopy -O binary $@.elf $@.bin 
	@riscv64-linux-gnu-objdump -d $@.elf >$@.dump

