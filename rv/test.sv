//
// RVOOM! Risc-V superscalar O-O
// Copyright (C) 2019-21 Paul Campbell - paul@taniwha.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// 

`timescale 1ns/10ps
module test;

	integer count;
	reg clk, reset;
	integer file, res;
	integer i;
	reg	  quit;
	parameter NCPU = 1;

	reg [31:0]gpio;
	reg [31:0]block_addr_0 = 0;
	reg [31:0]block_count_0 = 0;
	reg [31:0]block_addr_1 = 0;
	reg [31:0]block_count_1 = 0;

	initial begin 
		gpio= 0;
		$dumpvars;
		count=0;
		reset = 1;
		clk = 1;
`ifdef NOTDEF
		file = $fopenr("x.bin");
		res = $fread(chip.c[0].cpu.ic.icache, file);
		$fclose(file);
		for (res = 0;res < 65536;res=res+1) begin :rr
			reg [127:0]t;

			t = chip.c[0].cpu.ic.icache[res];
			t = {t[7:0],t[15:8],t[23:16],t[31:24],t[39:32],t[47:40],t[55:48], t[63:56],t[71:64],t[79:72],t[87:80], t[95:88],t[103:96],t[111:104],t[119:112], t[127:120]};
			chip.c[0].cpu.ic.icache[res] = t;
		end
`endif

		block_addr_0 = 0;
		block_count_0 = 0;
		block_addr_1 = 0;
		block_count_1 = 0;
		if ($test$plusargs ("b")) begin
			file = $fopenr("x.bin");
			quit = 0;
			for (i = 0;!quit;i=i+1) begin :rcx
				reg [63:0]t;

				res = $fread(t, file);
				if (res > 0) begin
					t = {t[7:0],t[15:8],t[23:16],t[31:24],t[39:32],t[47:40],t[55:48], t[63:56]};
                                	chip.io_switch.sd.disk[i] = t;
				end else begin
					quit = 1;
				end
			end
			$fclose(file);
			gpio = 1;
			block_addr_0 = 0;
			block_count_0 = ((i>>5)+1);
		end else begin
			file = $fopenr("x.bin");
			res = $fread(chip.mem.mem, file);
			$fclose(file);
			for (res = 0;res < 65536;res=res+1) begin :rc
				reg [511:0]t;
	
				t = chip.mem.mem[res];
				t = {t[7:0],t[15:8],t[23:16],t[31:24],t[39:32],t[47:40],t[55:48], t[63:56],t[71:64],t[79:72],t[87:80], t[95:88],t[103:96],t[111:104],t[119:112], t[127:120],
			     	t[135:128],t[143:136],t[151:144],t[159:152],t[167:160],t[175:168],t[183:176], t[191:184],t[199:192],t[207:200],t[215:208], t[223:216],t[231:224],t[239:232],t[247:240], t[255:248],
			     	t[263:256],t[271:264],t[279:272],t[287:280],t[295:288],t[303:296],t[311:304], t[319:312],t[327:320],t[335:328],t[343:336], t[351:344],t[359:352],t[367:360],t[375:368], t[383:376],
			     	t[391:384],t[399:392],t[407:400],t[415:408],t[423:416],t[431:424],t[439:432], t[447:440],t[455:448],t[463:456],t[471:464], t[479:472],t[487:480],t[495:488],t[503:496], t[511:504]};
				chip.mem.mem[res] = t;
			end
		end
		#5 clk=0;
		reset = 1;
		#10 clk=1;
		#5 clk=0;
		reset = 0;
		forever begin
			#5 clk=1;
			#5 clk=0;

		end
	end

	integer limit;
	initial begin
		if (!$value$plusargs("l=%d", limit)) 
			limit = 10000;
	end
	
	always @(posedge clk)
	if (!reset) begin
		count = count+1;
		//if (count > 100000)
		//if (count > 20000)
		//if (count > 50000)
		//if (count > 600000)
		if (count > limit)
			$finish;
	end

	wire [31:0]gpio_pads = gpio;
	wire	reset_out;

	chip #(.NCPU(NCPU))chip(.clk_in(clk), .ireset(reset),
		.reset_out(reset_out),
		.reset_out_ack(reset_out),
`ifdef SIMD
		.simd_enable(1'b1),
`endif
		.uart_rx(1'b0),
		.uart_cts(1'b0),
		.cpu_id(5'd0),
		.block_count_0(block_count_0),
		.block_addr_0(block_addr_0),
		.block_count_1(block_count_1),
		.block_addr_1(block_addr_1),
		.gpio_pads(gpio_pads));

endmodule
