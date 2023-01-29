XCC ?= riscv64-unknown-linux-gnu-gcc
XLD ?= riscv64-unknown-linux-gnu-ld
XOBJCOPY ?= riscv64-unknown-linux-gnu-objcopy
XOBJDUMP ?= riscv64-unknown-linux-gnu-objdump
XVERILATOR ?= /usr/local/bin/verilator
XDTC ?= ~/dtc

CPU = \
	cpu.sv \
	decode.sv \
	rename.sv \
	commit.sv \
	alu.sv \
	shift.sv \
	mul.sv \
	alu_ctrl.sv \
	csr.sv \
	$(TRACE_V) \
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
	boot0.sv \
	boot1.sv \
	$(B)

IO = mi.sv \
	ioi.sv \
	rvtimer.sv \
	clic.sv \
	plic.sv \
	dtbrom.sv \
	rviodtb.sv \
	rvsd.sv \
	rvgpio.sv


SRC = $(CPU) chip.sv $(IO) 

INCLUDES = cache_protocol.si  pred_context.si lstypes.si

DRAM = mmem.sv 

SYNTH = \
	synth/vsram.v

#NALU_1 = +define+NALU4
#NALU_2 = -DNALU4
#MXREG = rfile_23_1_10_1_8_32_4.sv    # for NALU4 COMBINED
NALU_1 = +define+NALU3
NALU_2 = -DNALU3
MXREG = rfile_21_1_9_1_8_32_4.sv   # for NALU3 COMBINED
#NALU_1 = 
#NALU_2 = 
#MXREG = rfile_19_1_8_1_8_32_2.sv   # for NALU2 COMBINED

#TRACE_1 = +define+TRACE_CACHE
#TRACE_2 = -DTRACE_CACHE
#TRACE_V = trc.sv
TRACE_1 = 
TRACE_2 = 
TRACE_V = 

#RENAME_OPT_1 = +define+RENAME_OPT
#RENAME_OPT_2 = -DRENAME_OPT
RENAME_OPT_1 = 
RENAME_OPT_2 =

NSTORE2_1 = 
NSTORE2_2 = 
#NSTORE2_1 =
#NSTORE2_2 =

# ------ enable the first 3 for a separate branch unit, the second for combined alu/branch
#B = branch.sv
#CB_1 = branch.sv
#CB_2 = branch.sv
B = 
CB_1 = +define+COMBINED_BRANCH
CB_2 = -DCOMBINED_BRANCH
# ------


OPT_FLAG_1 = $(NALU_1) $(NSTORE2_1) $(CB_1) $(TRACE_1) $(RENAME_OPT_1)
OPT_FLAG_2 = $(NALU_2) $(NSTORE2_2) $(CB_2) $(TRACE_2) $(RENAME_OPT_2)
XTEST = aws-design/design/cl_template.sv synth/vsram.v synth/mmem.sv xcels.sv
XSYNTH1 = +define+VSYNTH  +define+VS2 +incdir+aws-design/design +incdir+aws-fpga/hdk/common/shell_v04261818/design/interfaces +define+VVV  $(OPT_FLAG_1)
XSYNTH2 = -DPSYNTH -DVSYNTH -DVS2 -Iaws-design/design -Iaws-fpga/hdk/common/shell_v04261818/design/interfaces -DVVV $(OPT_FLAG_2)

FPU = fp.sv fp_add.sv fp_mul.sv fp_div.sv
FPINC = mkf1.inc mkf2.inc mkf3.inc mkf4.inc mkf6.inc mkf7.inc mkf8.inc mkf9.inc mkf10.inc mkf11.inc


VSYNTH1 = +define+VSYNTH +define+VSYNTH2 $(OPT_FLAG_1)
VSYNTH2 = -D VSYNTH $(OPT_FLAG_2)

UART = rvuart.sv uart/raminfr.v uart/uart_receiver.v uart/uart_regs.v uart/uart_rfifo.v  uart/uart_sync_flops.v  uart/uart_tfifo.v uart/uart_top.v uart/uart_transmitter.v  uart/uart_wb.v
UART_DEF1 = +incdir+uart 
UART_DEF2 = -Iuart 

VERILATOR= $(XVERILATOR) --error-limit 10 -j 16 --timescale-override "1ns/1ns" --trace-max-array 64

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
MX14 = mk14_6_4_4_1_1.inc mk14_4_2_2_1_1.inc mk14_6_4_4_1_0.inc mk14_4_2_2_1_0.inc
MX15 = mk15_10_2.inc mk15_11_2.inc mk15_12_2.inc mk15_15_2.inc mk15_14_2.inc \
	mk15_10_1.inc mk15_11_1.inc mk15_12_1.inc mk15_15_1.inc mk15_14_1.inc \
	mk15_16_1.inc mk15_16_2.inc
MX16 = mk16_8.inc mk16_16.inc mk16_32.inc
MX17 = mk17_1_6.inc mk17_1_5.inc  mk17_1_4.inc
MX19 = mk19_64.inc 
MX20 = mk20_32_8.inc mk20_32_16.inc
MX21 = mk21_32_6_4_4_16.inc mk21_32_4_2_2_16.inc mk21_32_6_4_4_32.inc mk21_32_4_2_2_32.inc
MX22 = mk22_16_8.inc mk22_32_8.inc mk22_48_8.inc  mk22_64_8.inc mk22_128_8.inc mk22_96_8.inc
MX23 = mk23_8.inc 
#MXREG = rfile_13_3_6_2_8_32_1.sv 
#MXREG = rfile_15_3_7_2_8_32_1.sv
#MXREG = rfile_19_3_8_2_8_32_2.sv
MXREGX = rfile_15_3_6_2_8_32_2.sv
FMXREG = rfile_22_1_10_1_8_32_7.sv
#FMXREG = rfile_14_3_7_2_8_32_4.sv # rfile_16_3_8_2_8_32_4.sv
#MXREG = rfile_16_3_7_2_8_32.sv
MXREGINC =  rfile_16_3_7_2_4_32_1.inc rfile_16_3_7_2_8_32_1.inc rfile_13_3_6_2_4_32_1.inc rfile_13_3_6_2_8_32_1.inc \
	    rfile_16_3_7_2_4_32_4.inc rfile_16_3_7_2_8_32_4.inc rfile_13_3_6_2_4_32_4.inc rfile_13_3_6_2_8_32_4.inc \
	   rfile_14_3_7_2_4_32_4.inc rfile_14_3_7_2_4_32_1.inc rfile_14_3_7_2_8_32_4.inc rfile_16_3_8_2_8_32_4.inc \
	  rfile_15_3_7_2_4_32_1.inc rfile_15_3_7_2_8_32_1.inc rfile_15_3_6_2_8_32_2.inc rfile_15_3_6_2_4_32_2.inc \
		rfile_19_3_8_2_8_32_2.inc  rfile_19_1_8_1_8_32_2.inc rfile_21_1_9_1_8_32_4.inc rfile_23_1_10_1_8_32_4.inc \
	rfile_22_1_10_1_8_32_7.inc rfile_22_1_10_1_8_32_7.inc rfile_24_1_11_1_8_32_7.inc rfile_20_1_9_1_8_32_7.inc rfile_20_1_9_1_4_32_7.inc
		
MXCTRL = alu_ctrl_hdr_4_1_32_2_1_1_1_0.inc  alu_ctrl_core_4_1_32_2_1_1_1_0.inc  alu_ctrl_inst_4_1_32_2_1_1_1_0.inc   alu_ctrl_hdr_4_1_32_3_1_1_1_0.inc \
	alu_ctrl_hdr_4_1_32_2_1_1_1_1.inc alu_ctrl_core_4_1_32_2_1_1_1_1.inc alu_ctrl_inst_4_1_32_2_1_1_1_1.inc alu_ctrl_inst_4_1_32_3_1_1_1_0.inc alu_ctrl_core_4_1_32_3_1_1_1_0.inc \
	alu_ctrl_inst_4_1_32_2_1_0_1_1.inc alu_ctrl_inst_4_1_32_3_1_0_1_0.inc alu_ctrl_inst_4_1_32_2_1_0_1_0.inc \
	alu_ctrl_core_4_1_32_2_1_0_1_1.inc alu_ctrl_core_4_1_32_3_1_0_1_0.inc alu_ctrl_core_4_1_32_2_1_0_1_0.inc \
	alu_ctrl_hdr_4_1_32_2_1_0_1_1.inc alu_ctrl_hdr_4_1_32_3_1_0_1_0.inc alu_ctrl_hdr_4_1_32_2_1_0_1_0.inc \
	alu_ctrl_hdr_4_1_32_4_1_0_1_0.inc alu_ctrl_core_4_1_32_4_1_0_1_0.inc alu_ctrl_inst_4_1_32_4_1_0_1_0.inc \
	alu_ctrl_inst_4_1_32_3_1_0_1_1.inc alu_ctrl_hdr_4_1_32_3_1_0_1_1.inc alu_ctrl_core_4_1_32_3_1_0_1_1.inc \
	alu_ctrl_inst_4_1_32_4_1_0_1_1.inc alu_ctrl_hdr_4_1_32_4_1_0_1_1.inc alu_ctrl_core_4_1_32_4_1_0_1_1.inc
MXA = $(MX) $(MX2) $(MX3) $(MX4) $(MX5) $(MX6) $(MX7) $(MX8) $(MX9) $(MX10) $(MX11) $(MX12) $(MX13) $(MX14) $(MX15) $(MX16) $(MX17) $(MX19) $(MX20) $(MX21) $(MX22) $(MX23) $(MXREG) $(MXREGINC) $(MXCTRL) $(MXREGX)

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

alu_ctrl_hdr_4_1_32_2_1_0_1_0.inc:	mkctrl 
	./mkctrl -hdr 4 1 32 2 1 0 1 0 >$@
alu_ctrl_core_4_1_32_2_1_0_1_0.inc:	mkctrl
	./mkctrl -core 4 1 32 2 1 0 1 0 >$@
alu_ctrl_inst_4_1_32_2_1_0_1_0.inc:	mkctrl
	./mkctrl -inst 4 1 32 2 1 0 1 0 >$@

alu_ctrl_hdr_4_1_32_4_1_0_1_0.inc:	mkctrl 
	./mkctrl -hdr 4 1 32 4 1 0 1 0 >$@
alu_ctrl_core_4_1_32_4_1_0_1_0.inc:	mkctrl
	./mkctrl -core 4 1 32 4 1 0 1 0 >$@
alu_ctrl_inst_4_1_32_4_1_0_1_0.inc:	mkctrl
	./mkctrl -inst 4 1 32 4 1 0 1 0 >$@

alu_ctrl_hdr_4_1_32_3_1_0_1_0.inc:	mkctrl 
	./mkctrl -hdr 4 1 32 3 1 0 1 0 >$@
alu_ctrl_core_4_1_32_3_1_0_1_0.inc:	mkctrl
	./mkctrl -core 4 1 32 3 1 0 1 0 >$@
alu_ctrl_inst_4_1_32_3_1_0_1_0.inc:	mkctrl
	./mkctrl -inst 4 1 32 3 1 0 1 0 >$@

alu_ctrl_hdr_4_1_32_2_1_0_1_1.inc:	mkctrl 
	./mkctrl -hdr 4 1 32 2 1 0 1 1 >$@
alu_ctrl_core_4_1_32_2_1_0_1_1.inc:	mkctrl
	./mkctrl -core 4 1 32 2 1 0 1 1 >$@
alu_ctrl_inst_4_1_32_2_1_0_1_1.inc:	mkctrl
	./mkctrl -inst 4 1 32 2 1 0 1 1 >$@
alu_ctrl_hdr_4_1_32_2_1_1_0_1_1.inc:	mkctrl 
	./mkctrl -hdr 4 1 32 2 1 0 1 1 >$@

alu_ctrl_hdr_4_1_32_2_1_1_1_0.inc:	mkctrl 
	./mkctrl -hdr 4 1 32 2 1 1 1 0 >$@
alu_ctrl_core_4_1_32_2_1_1_1_0.inc:	mkctrl
	./mkctrl -core 4 1 32 2 1 1 1 0 >$@
alu_ctrl_inst_4_1_32_2_1_1_1_0.inc:	mkctrl
	./mkctrl -inst 4 1 32 2 1 1 1 0 >$@

alu_ctrl_hdr_4_1_32_3_1_0_1_1.inc:	mkctrl
	./mkctrl -hdr 4 1 32 3 1 0 1 1 >$@
alu_ctrl_core_4_1_32_3_1_0_1_1.inc:	mkctrl
	./mkctrl -core 4 1 32 3 1 0 1 1 >$@
alu_ctrl_inst_4_1_32_3_1_0_1_1.inc:	mkctrl
	./mkctrl -inst 4 1 32 3 1 0 1 1 >$@

alu_ctrl_hdr_4_1_32_4_1_0_1_1.inc:	mkctrl
	./mkctrl -hdr 4 1 32 4 1 0 1 1 >$@
alu_ctrl_core_4_1_32_4_1_0_1_1.inc:	mkctrl
	./mkctrl -core 4 1 32 4 1 0 1 1 >$@
alu_ctrl_inst_4_1_32_4_1_0_1_1.inc:	mkctrl
	./mkctrl -inst 4 1 32 4 1 0 1 1 >$@


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

rfile_16_3_8_2_8_32_4.sv:	rfile
	./rfile 16 3 8 2 8 32 4 >$@
rfile_16_3_8_2_8_32_4.inc:	rfile
	./rfile -inc 16 3 8 2 8 32 4 >$@

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

rfile_19_1_8_1_8_32_2.sv:	rfile
	./rfile 19 1 8 1 8 32 2 >$@
rfile_19_1_8_1_8_32_2.inc:	rfile
	./rfile -inc 19 1 8 1 8 32 2 >$@

rfile_21_1_9_1_8_32_4.sv:	rfile
	./rfile      21 1 9 1 8 32 4 >$@
rfile_21_1_9_1_8_32_4.inc:	rfile
	./rfile -inc 21 1 9 1 8 32 4 >$@

rfile_23_1_10_1_8_32_4.sv:	rfile
	./rfile      23 1 10 1 8 32 4 >$@
rfile_23_1_10_1_8_32_4.inc:	rfile
	./rfile -inc 23 1 10 1 8 32 4 >$@

rfile_20_1_9_1_4_32_7.sv:	rfile
	./rfile      20 1 9 1 4 32 7 >$@
rfile_20_1_9_1_4_32_7.inc:	rfile
	./rfile -inc 20 1 9 1 4 32 7 >$@

rfile_20_1_9_1_8_32_7.sv:	rfile
	./rfile      20 1 9 1 8 32 7 >$@
rfile_20_1_9_1_8_32_7.inc:	rfile
	./rfile -inc 20 1 9 1 8 32 7 >$@

rfile_22_1_10_1_8_32_7.sv:	rfile
	./rfile      22 1 10 1 8 32 7 >$@
rfile_22_1_10_1_8_32_7.inc:	rfile
	./rfile -inc 22 1 10 1 8 32 7 >$@

rfile_24_1_11_1_8_32_7.sv:	rfile
	./rfile      24 1 11 1 8 32 7 >$@
rfile_24_1_11_1_8_32_7.inc:	rfile
	./rfile -inc 24 1 11 1 8 32 7 >$@

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
mk14_6_4_4_1_0.inc: mk14
	./mk14 6 4 4 1 0 >$@
mk14_4_2_2_1_0.inc: mk14
	./mk14 4 2 2 1 0 >$@
mk14_6_4_4_1_1.inc: mk14
	./mk14 6 4 4 1 1 >$@
mk14_4_2_2_1_1.inc: mk14
	./mk14 4 2 2 1 1 >$@

mk15:	mk15.c
	gcc -o mk15 mk15.c
mk15_10_2.inc: mk15
	./mk15 10 1 >$@
mk15_11_2.inc: mk15
	./mk15 11 1 >$@
mk15_12_2.inc: mk15
	./mk15 12 1 >$@
mk15_14_2.inc: mk15
	./mk15 14 1 >$@
mk15_15_2.inc: mk15
	./mk15 15 1 >$@
mk15_16_2.inc: mk15
	./mk15 16 1 >$@
mk15_10_1.inc: mk15
	./mk15 10 1 >$@
mk15_11_1.inc: mk15
	./mk15 11 1 >$@
mk15_12_1.inc: mk15
	./mk15 12 1 >$@
mk15_14_1.inc: mk15
	./mk15 14 1 >$@
mk15_15_1.inc: mk15
	./mk15 15 1 >$@
mk15_16_1.inc: mk15
	./mk15 16 1 >$@

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

mk22:	mk22.c
	gcc -o mk22 mk22.c

mk22_16_8.inc: mk22
	./mk22 16 8 >$@
mk22_32_8.inc: mk22
	./mk22 32 8 >$@
mk22_48_8.inc: mk22
	./mk22 48 8 >$@
mk22_64_8.inc: mk22
	./mk22 64 8 >$@
mk22_96_8.inc: mk22
	./mk22 96 8 >$@
mk22_128_8.inc: mk22
	./mk22 128 8 >$@

mk23:	mk23.c
	gcc -o mk23 mk23.c

mk23_8.inc: mk23
	./mk23 8 >$@

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

mkf7:	mkf7.c
	gcc -o mkf7 mkf7.c
mkf7.inc:	mkf7
	./mkf7 >$@

mkf8:	mkf8.c
	gcc -o mkf8 mkf8.c
mkf8.inc:	mkf8
	./mkf8 >$@

mkf9:	mkf9.c
	gcc -o mkf9 mkf9.c
mkf9.inc:	mkf9
	./mkf9 >$@

mkf10:	mkf10.c
	gcc -o mkf10 mkf10.c
mkf10.inc:	mkf10
	./mkf10 >$@

mkf11:	mkf11.c
	gcc -o mkf11 mkf11.c
mkf11.inc:	mkf11
	./mkf11 >$@

fptest/fp_add_test_32.txt:	fptest/timesoftfloat32
	fptest/timesoftfloat32 -nearesteven float32_add > fptest/fp_add_test_32.txt
	fptest/timesoftfloat32 -nearesteven float32_sub >> fptest/fp_add_test_32.txt
	fptest/timesoftfloat32 -tozero float32_add >> fptest/fp_add_test_32.txt
	fptest/timesoftfloat32 -tozero float32_sub >> fptest/fp_add_test_32.txt
	fptest/timesoftfloat32 -up float32_add >> fptest/fp_add_test_32.txt
	fptest/timesoftfloat32 -up float32_sub >> fptest/fp_add_test_32.txt
	fptest/timesoftfloat32 -down float32_add >> fptest/fp_add_test_32.txt
	fptest/timesoftfloat32 -down float32_sub >> fptest/fp_add_test_32.txt

fptest/fp_add_test_64.txt:	fptest/timesoftfloat32
	fptest/timesoftfloat32 -nearesteven float64_add > fptest/fp_add_test_64.txt
	fptest/timesoftfloat32 -nearesteven float64_sub >> fptest/fp_add_test_64.txt
	fptest/timesoftfloat32 -tozero float64_add >> fptest/fp_add_test_64.txt
	fptest/timesoftfloat32 -tozero float64_sub >> fptest/fp_add_test_64.txt
	fptest/timesoftfloat32 -up float64_add >> fptest/fp_add_test_64.txt
	fptest/timesoftfloat32 -up float64_sub >> fptest/fp_add_test_64.txt
	fptest/timesoftfloat32 -down float64_add >> fptest/fp_add_test_64.txt
	fptest/timesoftfloat32 -down float64_sub >> fptest/fp_add_test_64.txt

fptest/fp_mul_test_32.txt:     fptest/timesoftfloat32
	fptest/timesoftfloat32 -nearesteven float32_mul > fptest/fp_mul_test_32.txt
	fptest/timesoftfloat32 -tozero float32_mul >> fptest/fp_mul_test_32.txt
	fptest/timesoftfloat32 -up float32_mul >> fptest/fp_mul_test_32.txt
	fptest/timesoftfloat32 -down float32_mul >> fptest/fp_mul_test_32.txt

fptest/fp_mul_test_64.txt:     fptest/timesoftfloat32
	fptest/timesoftfloat32 -nearesteven float64_mul > fptest/fp_mul_test_64.txt
	fptest/timesoftfloat32 -tozero float64_mul >> fptest/fp_mul_test_64.txt
	fptest/timesoftfloat32 -up float64_mul >> fptest/fp_mul_test_64.txt
	fptest/timesoftfloat32 -down float64_mul >> fptest/fp_mul_test_64.txt

#	fptest/timesoftfloat32 -nearesteven float32_div >> testcases.txt 
#	fptest/timesoftfloat32 -nearesteven float32_sqrt >> testcases.txt 
#	fptest/timesoftfloat32 -tozero float32_div >> testcases.txt 
#	fptest/timesoftfloat32 -tozero float32_sqrt >> testcases.txt 
#	fptest/timesoftfloat32 -up float32_div >> testcases.txt 
#	fptest/timesoftfloat32 -up float32_sqrt >> testcases.txt 
#	fptest/timesoftfloat32 -down float32_div >> testcases.txt 
#	fptest/timesoftfloat32 -down float32_sqrt >> testcases.txt



cvtbin:	cvtbin.c
	gcc -o cvtbin cvtbin.c

mk: x.bin

boot0.sv:	boot0.s cvtbin
	$(XCC) -c boot0.s -march=rv64imac
	$(XLD) -N -o boot0.elf -e start -Ttext-segment=0 -N -static boot0.o -Tlink.ld
	$(XOBJCOPY) -O binary boot0.elf boot0.bin
	./cvtbin boot0.bin bootrom0 128 >boot0.sv

boot1.sv:	boot1.s cvtbin
	$(XCC) -c boot1.s -march=rv64imac
	$(XLD) -N -o boot1.elf -e start -Ttext-segment=0 -N -static boot1.o -Tlink.ld
	$(XOBJCOPY) -O binary boot1.elf boot1.bin
	./cvtbin boot1.bin bootrom1 128 >boot1.sv

dtbrom.sv:	sv.dtb cvtbin
	./cvtbin sv.dtb dtbrom 64 >dtbrom.sv

cache_test:	cache.s
	$(XCC) -c cache.s -march=rv64im
	$(XLD) -N -o x -e start -Ttext-segment=0 -N -static cache.o -Tlink.ld
	$(XOBJCOPY) -O binary x x.bin
	$(XOBJDUMP) -d x >x.lst


x.bin:	x.s
	$(XCC) -c x.s -march=rv64im
	$(XLD) -N -o x -e start -Ttext-segment=0 -N -static x.o -Tlink.ld
	$(XOBJCOPY) -O binary x x.bin
	$(XOBJDUMP) -d x >x.lst

bbl.bin: linux/riscv-pk/build/bbl
	$(XOBJCOPY) -O binary linux/riscv-pk/build/bbl bbl.bin
	$(XOBJDUMP) -d linux/riscv-pk/build/bbl >bbl.lst

opensbi.bin: linux/opensbi-master/build/platform/moonbase/firmware/fw_jump.elf
	$(XOBJCOPY) -O binary linux/opensbi-master/build/platform/moonbase/firmware/fw_jump.elf opensbi.bin
	$(XOBJDUMP) -d linux/opensbi-master/build/platform/moonbase/firmware/fw_jump.elf >opensbi.lst

sv.dtb:	sv.dts
	$(XDTC) -I dts sv.dts -o sv.dtb

fpt:	testfp.sv fp_add.sv mkf1.inc mkf2.inc fp_mul.sv mkf3.inc mkf9.inc fp_div.sv mkf10.inc mkf11.inc
	iverilog testfp.sv fp_add.sv fp_mul.sv fp_div.sv -g 2005-sv -o fpt

fpadd32:	fpt fptest/fp_add_test_32.txt
	./fpt +s

fpadd64:	fpt fptest/fp_add_test_64.txt
	./fpt +d

fpmul32:	fpt fptest/fp_mul_test_32.txt
	./fpt +s +m

fpmul64:	fpt fptest/fp_mul_test_64.txt
	./fpt +d +m

fptest/f_add_test_16.txt:
	echo "o 0" >fptest/f_add_test_16.txt
	echo "s 2" >>fptest/f_add_test_16.txt
	echo "r 0" >>fptest/f_add_test_16.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f16_add >>fptest/f_add_test_16.txt
	echo "r 1" >>fptest/f_add_test_16.txt
	fptest/testfloat_gen -rminMag -n 1000000 f16_add >>fptest/f_add_test_16.txt
	echo "r 2" >>fptest/f_add_test_16.txt
	fptest/testfloat_gen -rmin -n 1000000 f16_add >>fptest/f_add_test_16.txt
	echo "r 3" >>fptest/f_add_test_16.txt
	fptest/testfloat_gen -rmax -n 1000000 f16_add >>fptest/f_add_test_16.txt
	echo "r 4" >>fptest/f_add_test_16.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f16_add >>fptest/f_add_test_16.txt
	echo "o 1" >>fptest/f_add_test_16.txt
	echo "r 0" >>fptest/f_add_test_16.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f16_sub >>fptest/f_add_test_16.txt
	echo "r 1" >>fptest/f_add_test_16.txt
	fptest/testfloat_gen -rminMag -n 1000000 f16_sub >>fptest/f_add_test_16.txt
	echo "r 2" >>fptest/f_add_test_16.txt
	fptest/testfloat_gen -rmin -n 1000000 f16_sub >>fptest/f_add_test_16.txt
	echo "r 3" >>fptest/f_add_test_16.txt
	fptest/testfloat_gen -rmax -n 1000000 f16_sub >>fptest/f_add_test_16.txt
	echo "r 4" >>fptest/f_add_test_16.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f16_sub >>fptest/f_add_test_16.txt

fptest/f_add_test_32.txt:
	echo "o 0" >fptest/f_add_test_32.txt
	echo "s 0" >>fptest/f_add_test_32.txt
	echo "r 0" >>fptest/f_add_test_32.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f32_add >>fptest/f_add_test_32.txt
	echo "r 1" >>fptest/f_add_test_32.txt
	fptest/testfloat_gen -rminMag -n 1000000 f32_add >>fptest/f_add_test_32.txt
	echo "r 2" >>fptest/f_add_test_32.txt
	fptest/testfloat_gen -rmin -n 1000000 f32_add >>fptest/f_add_test_32.txt
	echo "r 3" >>fptest/f_add_test_32.txt
	fptest/testfloat_gen -rmax -n 1000000 f32_add >>fptest/f_add_test_32.txt
	echo "r 4" >>fptest/f_add_test_32.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f32_add >>fptest/f_add_test_32.txt
	echo "o 1" >>fptest/f_add_test_32.txt
	echo "r 0" >>fptest/f_add_test_32.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f32_sub >>fptest/f_add_test_32.txt
	echo "r 1" >>fptest/f_add_test_32.txt
	fptest/testfloat_gen -rminMag -n 1000000 f32_sub >>fptest/f_add_test_32.txt
	echo "r 2" >>fptest/f_add_test_32.txt
	fptest/testfloat_gen -rmin -n 1000000 f32_sub >>fptest/f_add_test_32.txt
	echo "r 3" >>fptest/f_add_test_32.txt
	fptest/testfloat_gen -rmax -n 1000000 f32_sub >>fptest/f_add_test_32.txt
	echo "r 4" >>fptest/f_add_test_32.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f32_sub >>fptest/f_add_test_32.txt

fptest/f_add_test_64.txt:
	echo "o 0" >fptest/f_add_test_64.txt
	echo "s 1" >>fptest/f_add_test_64.txt
	echo "r 0" >>fptest/f_add_test_64.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f64_add >>fptest/f_add_test_64.txt
	echo "r 1" >>fptest/f_add_test_64.txt
	fptest/testfloat_gen -rminMag -n 1000000 f64_add >>fptest/f_add_test_64.txt
	echo "r 2" >>fptest/f_add_test_64.txt
	fptest/testfloat_gen -rmin -n 1000000 f64_add >>fptest/f_add_test_64.txt
	echo "r 3" >>fptest/f_add_test_64.txt
	fptest/testfloat_gen -rmax -n 1000000 f64_add >>fptest/f_add_test_64.txt
	echo "r 4" >>fptest/f_add_test_64.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f64_add >>fptest/f_add_test_64.txt
	echo "o 1" >>fptest/f_add_test_64.txt
	echo "r 0" >>fptest/f_add_test_64.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f64_sub >>fptest/f_add_test_64.txt
	echo "r 1" >>fptest/f_add_test_64.txt
	fptest/testfloat_gen -rminMag -n 1000000 f64_sub >>fptest/f_add_test_64.txt
	echo "r 2" >>fptest/f_add_test_64.txt
	fptest/testfloat_gen -rmin -n 1000000 f64_sub >>fptest/f_add_test_64.txt
	echo "r 3" >>fptest/f_add_test_64.txt
	fptest/testfloat_gen -rmax -n 1000000 f64_sub >>fptest/f_add_test_64.txt
	echo "r 4" >>fptest/f_add_test_64.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f64_sub >>fptest/f_add_test_64.txt

fptest/f_div_test_16.txt:
	echo "o 7" >fptest/f_div_test_16.txt
	echo "s 2" >>fptest/f_div_test_16.txt
	echo "r 0" >>fptest/f_div_test_16.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f16_div >>fptest/f_div_test_16.txt
	echo "r 1" >>fptest/f_div_test_16.txt
	fptest/testfloat_gen -rminMag -n 1000000 f16_div >>fptest/f_div_test_16.txt
	echo "r 2" >>fptest/f_div_test_16.txt
	fptest/testfloat_gen -rmin -n 1000000 f16_div >>fptest/f_div_test_16.txt
	echo "r 3" >>fptest/f_div_test_16.txt
	fptest/testfloat_gen -rmax -n 1000000 f16_div >>fptest/f_div_test_16.txt
	echo "r 4" >>fptest/f_div_test_16.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f16_div >>fptest/f_div_test_16.txt

fptest/f_div_test_32.txt:
	echo "o 7" >fptest/f_div_test_32.txt
	echo "s 0" >>fptest/f_div_test_32.txt
	echo "r 0" >>fptest/f_div_test_32.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f32_div >>fptest/f_div_test_32.txt
	echo "r 1" >>fptest/f_div_test_32.txt
	fptest/testfloat_gen -rminMag -n 1000000 f32_div >>fptest/f_div_test_32.txt
	echo "r 2" >>fptest/f_div_test_32.txt
	fptest/testfloat_gen -rmin -n 1000000 f32_div >>fptest/f_div_test_32.txt
	echo "r 3" >>fptest/f_div_test_32.txt
	fptest/testfloat_gen -rmax -n 1000000 f32_div >>fptest/f_div_test_32.txt
	echo "r 4" >>fptest/f_div_test_32.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f32_div >>fptest/f_div_test_32.txt

fptest/f_div_test_64.txt:
	echo "o 7" >fptest/f_div_test_64.txt
	echo "s 1" >>fptest/f_div_test_64.txt
	echo "r 0" >>fptest/f_div_test_64.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f64_div >>fptest/f_div_test_64.txt
	echo "r 1" >>fptest/f_div_test_64.txt
	fptest/testfloat_gen -rminMag -n 1000000 f64_div >>fptest/f_div_test_64.txt
	echo "r 2" >>fptest/f_div_test_64.txt
	fptest/testfloat_gen -rmin -n 1000000 f64_div >>fptest/f_div_test_64.txt
	echo "r 3" >>fptest/f_div_test_64.txt
	fptest/testfloat_gen -rmax -n 1000000 f64_div >>fptest/f_div_test_64.txt
	echo "r 4" >>fptest/f_div_test_64.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f64_div >>fptest/f_div_test_64.txt

fptest/f_sqrt_test_16.txt:
	echo "o 8" >fptest/f_sqrt_test_16.txt
	echo "s 2" >>fptest/f_sqrt_test_16.txt
	echo "r 0" >>fptest/f_sqrt_test_16.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f16_sqrt >>fptest/f_sqrt_test_16.txt
	echo "r 1" >>fptest/f_sqrt_test_16.txt
	fptest/testfloat_gen -rminMag -n 1000000 f16_sqrt >>fptest/f_sqrt_test_16.txt
	echo "r 2" >>fptest/f_sqrt_test_16.txt
	fptest/testfloat_gen -rmin -n 1000000 f16_sqrt >>fptest/f_sqrt_test_16.txt
	echo "r 3" >>fptest/f_sqrt_test_16.txt
	fptest/testfloat_gen -rmax -n 1000000 f16_sqrt >>fptest/f_sqrt_test_16.txt
	echo "r 4" >>fptest/f_sqrt_test_16.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f16_sqrt >>fptest/f_sqrt_test_16.txt

fptest/f_sqrt_test_32.txt:
	echo "o 8" >fptest/f_sqrt_test_32.txt
	echo "s 0" >>fptest/f_sqrt_test_32.txt
	echo "r 0" >>fptest/f_sqrt_test_32.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f32_sqrt >>fptest/f_sqrt_test_32.txt
	echo "r 1" >>fptest/f_sqrt_test_32.txt
	fptest/testfloat_gen -rminMag -n 1000000 f32_sqrt >>fptest/f_sqrt_test_32.txt
	echo "r 2" >>fptest/f_sqrt_test_32.txt
	fptest/testfloat_gen -rmin -n 1000000 f32_sqrt >>fptest/f_sqrt_test_32.txt
	echo "r 3" >>fptest/f_sqrt_test_32.txt
	fptest/testfloat_gen -rmax -n 1000000 f32_sqrt >>fptest/f_sqrt_test_32.txt
	echo "r 4" >>fptest/f_sqrt_test_32.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f32_sqrt >>fptest/f_sqrt_test_32.txt

fptest/f_sqrt_test_64.txt:
	echo "o 8" >fptest/f_sqrt_test_64.txt
	echo "s 1" >>fptest/f_sqrt_test_64.txt
	echo "r 0" >>fptest/f_sqrt_test_64.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f64_sqrt >>fptest/f_sqrt_test_64.txt
	echo "r 1" >>fptest/f_sqrt_test_64.txt
	fptest/testfloat_gen -rminMag -n 1000000 f64_sqrt >>fptest/f_sqrt_test_64.txt
	echo "r 2" >>fptest/f_sqrt_test_64.txt
	fptest/testfloat_gen -rmin -n 1000000 f64_sqrt >>fptest/f_sqrt_test_64.txt
	echo "r 3" >>fptest/f_sqrt_test_64.txt
	fptest/testfloat_gen -rmax -n 1000000 f64_sqrt >>fptest/f_sqrt_test_64.txt
	echo "r 4" >>fptest/f_sqrt_test_64.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f64_sqrt >>fptest/f_sqrt_test_64.txt

fptest/f_mul_test_16.txt:
	echo "o 2" >fptest/f_mul_test_16.txt
	echo "s 2" >>fptest/f_mul_test_16.txt
	echo "r 0" >>fptest/f_mul_test_16.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f16_mul >>fptest/f_mul_test_16.txt
	echo "r 1" >>fptest/f_mul_test_16.txt
	fptest/testfloat_gen -rminMag -n 1000000 f16_mul >>fptest/f_mul_test_16.txt
	echo "r 2" >>fptest/f_mul_test_16.txt
	fptest/testfloat_gen -rmin -n 1000000 f16_mul >>fptest/f_mul_test_16.txt
	echo "r 3" >>fptest/f_mul_test_16.txt
	fptest/testfloat_gen -rmax -n 1000000 f16_mul >>fptest/f_mul_test_16.txt
	echo "r 4" >>fptest/f_mul_test_16.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f16_mul >>fptest/f_mul_test_16.txt

fptest/f_mul_test_32.txt:
	echo "o 2" >fptest/f_mul_test_32.txt
	echo "s 0" >>fptest/f_mul_test_32.txt
	echo "r 0" >>fptest/f_mul_test_32.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f32_mul >>fptest/f_mul_test_32.txt
	echo "r 1" >>fptest/f_mul_test_32.txt
	fptest/testfloat_gen -rminMag -n 1000000 f32_mul >>fptest/f_mul_test_32.txt
	echo "r 2" >>fptest/f_mul_test_32.txt
	fptest/testfloat_gen -rmin -n 1000000 f32_mul >>fptest/f_mul_test_32.txt
	echo "r 3" >>fptest/f_mul_test_32.txt
	fptest/testfloat_gen -rmax -n 1000000 f32_mul >>fptest/f_mul_test_32.txt
	echo "r 4" >>fptest/f_mul_test_32.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f32_mul >>fptest/f_mul_test_32.txt

fptest/f_mul_test_64.txt:
	echo "o 2" >fptest/f_mul_test_64.txt
	echo "s 1" >>fptest/f_mul_test_64.txt
	echo "r 0" >>fptest/f_mul_test_64.txt
	fptest/testfloat_gen -rnear_even -n 1000000 f64_mul >>fptest/f_mul_test_64.txt
	echo "r 1" >>fptest/f_mul_test_64.txt
	fptest/testfloat_gen -rminMag -n 1000000 f64_mul >>fptest/f_mul_test_64.txt
	echo "r 2" >>fptest/f_mul_test_64.txt
	fptest/testfloat_gen -rmin -n 1000000 f64_mul >>fptest/f_mul_test_64.txt
	echo "r 3" >>fptest/f_mul_test_64.txt
	fptest/testfloat_gen -rmax -n 1000000 f64_mul >>fptest/f_mul_test_64.txt
	echo "r 4" >>fptest/f_mul_test_64.txt
	fptest/testfloat_gen -rnear_maxMag -n 1000000 f64_mul >>fptest/f_mul_test_64.txt

fptest/f_mul_add_test_16.txt:
	echo "o 3" >fptest/f_mul_add_test_16.txt
	echo "s 2" >>fptest/f_mul_add_test_16.txt
	echo "r 0" >>fptest/f_mul_add_test_16.txt
	fptest/testfloat_gen -rnear_even -n 10000000 f16_mulAdd >>fptest/f_mul_add_test_16.txt
	echo "r 1" >>fptest/f_mul_add_test_16.txt
	fptest/testfloat_gen -rminMag -n 10000000 f16_mulAdd >>fptest/f_mul_add_test_16.txt
	echo "r 2" >>fptest/f_mul_add_test_16.txt
	fptest/testfloat_gen -rmin -n 10000000 f16_mulAdd >>fptest/f_mul_add_test_16.txt
	echo "r 3" >>fptest/f_mul_add_test_16.txt
	fptest/testfloat_gen -rmax -n 10000000 f16_mulAdd >>fptest/f_mul_add_test_16.txt
	echo "r 4" >>fptest/f_mul_add_test_16.txt
	fptest/testfloat_gen -rnear_maxMag -n 10000000 f16_mulAdd >>fptest/f_mul_add_test_16.txt

fptest/f_mul_add_test_32.txt:
	echo "o 3" >fptest/f_mul_add_test_32.txt
	echo "s 0" >>fptest/f_mul_add_test_32.txt
	echo "r 0" >>fptest/f_mul_add_test_32.txt
	fptest/testfloat_gen -rnear_even -n 10000000 f32_mulAdd >>fptest/f_mul_add_test_32.txt
	echo "r 1" >>fptest/f_mul_add_test_32.txt
	fptest/testfloat_gen -rminMag -n 10000000 f32_mulAdd >>fptest/f_mul_add_test_32.txt
	echo "r 2" >>fptest/f_mul_add_test_32.txt
	fptest/testfloat_gen -rmin -n 10000000 f32_mulAdd >>fptest/f_mul_add_test_32.txt
	echo "r 3" >>fptest/f_mul_add_test_32.txt
	fptest/testfloat_gen -rmax -n 10000000 f32_mulAdd >>fptest/f_mul_add_test_32.txt
	echo "r 4" >>fptest/f_mul_add_test_32.txt
	fptest/testfloat_gen -rnear_maxMag -n 10000000 f32_mulAdd >>fptest/f_mul_add_test_32.txt

fptest/f_mul_add_test_64.txt:
	echo "o 3" >fptest/f_mul_add_test_64.txt
	echo "s 1" >>fptest/f_mul_add_test_64.txt
	echo "r 0" >>fptest/f_mul_add_test_64.txt
	fptest/testfloat_gen -rnear_even -n 10000000 f64_mulAdd >>fptest/f_mul_add_test_64.txt
	echo "r 1" >>fptest/f_mul_add_test_64.txt
	fptest/testfloat_gen -rminMag -n 10000000 f64_mulAdd >>fptest/f_mul_add_test_64.txt
	echo "r 2" >>fptest/f_mul_add_test_64.txt
	fptest/testfloat_gen -rmin -n 10000000 f64_mulAdd >>fptest/f_mul_add_test_64.txt
	echo "r 3" >>fptest/f_mul_add_test_64.txt
	fptest/testfloat_gen -rmax -n 10000000 f64_mulAdd >>fptest/f_mul_add_test_64.txt
	echo "r 4" >>fptest/f_mul_add_test_64.txt
	fptest/testfloat_gen -rnear_maxMag -n 10000000 f64_mulAdd >>fptest/f_mul_add_test_64.txt

fadd16:	fpt fptest/f_add_test_16.txt
	./fpt +n +t=fptest/f_add_test_16.txt
fadd32:	fpt fptest/f_add_test_32.txt
	./fpt +n +t=fptest/f_add_test_32.txt
fadd64:	fpt fptest/f_add_test_64.txt
	./fpt +n +t=fptest/f_add_test_64.txt
fsqrt16:fpt fptest/f_sqrt_test_16.txt
	./fpt +n +t=fptest/f_sqrt_test_16.txt
fsqrt32:fpt fptest/f_sqrt_test_32.txt
	./fpt +n +t=fptest/f_sqrt_test_32.txt
fsqrt64:fpt fptest/f_sqrt_test_64.txt
	./fpt +n +t=fptest/f_sqrt_test_64.txt
fdiv16:	fpt fptest/f_div_test_16.txt
	./fpt  +n +t=fptest/f_div_test_16.txt
fdiv32:	fpt fptest/f_div_test_32.txt
	./fpt +n +t=fptest/f_div_test_32.txt
fdiv64:	fpt fptest/f_div_test_64.txt
	./fpt +n +t=fptest/f_div_test_64.txt
fmul16:	fpt fptest/f_mul_test_16.txt
	./fpt +n +t=fptest/f_mul_test_16.txt
fmul32:	fpt fptest/f_mul_test_32.txt
	./fpt +n +t=fptest/f_mul_test_32.txt
fmul64:	fpt fptest/f_mul_test_64.txt
	./fpt +n +t=fptest/f_mul_test_64.txt
fmuladd16:	fpt fptest/f_mul_add_test_16.txt
	./fpt +n +t=fptest/f_mul_add_test_16.txt
fmuladd32:	fpt fptest/f_mul_add_test_32.txt
	./fpt +n +t=fptest/f_mul_add_test_32.txt
fmuladd64:	fpt fptest/f_mul_add_test_64.txt
	./fpt +n +t=fptest/f_mul_add_test_64.txt

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

fp.bin:	fptest/fp.S  link.ld
	@$(XCC) -c fptest/fp.S -march=rv64imafdc -o fptest/fp.o
	@$(XLD) -N -e start -Ttext-segment=0 -N -static fptest/fp.o -o fptest/fp.elf -Tlink.ld
	@$(XOBJCOPY) -O binary fptest/fp.elf fp.bin 
	@$(XOBJDUMP) -d fptest/fp.elf >fp.dump


t:	t.S link.ld
	@$(XCC) -c $@.S -march=rv64imafdc -o $@.o
	@$(XLD) -N -e start -Ttext-segment=0 -N -static $@.o -o $@.elf -Tlink.ld
	@$(XOBJCOPY) -O binary $@.elf $@.bin 
	@$(XOBJDUMP) -d $@.elf >$@.dump

VLIST =  $(CPU) $(MXREG) 
v2v:	$(CPU) $(MXA) $(INCLUDES) 
	~/sky/sv2v/bin/sv2v --define=VSYNTH2 --define=COMBINED_BRANCH $(VLIST) -I . -w ~/sky/OpenLane/designs/rv/src/cpu.v  

