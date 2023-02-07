`ifdef VSYNTH

`ifndef VSYNTH2
`ifdef PSYNTH
module clockgen_simple(input clk_in, output clk, output locked);
	assign clk = clk_in;
	reg l;
	assign locked = l;
	initial begin
		l = 0;
		#100;
		l = 1;
	end
endmodule
`else
module clockgen(input clk_in1, output clk, output clkX4, output ph0, output ph1, output ph2, output ph3);

	assign clk = clk_in1;
	reg r;
	assign clkX4=r;
	reg p0, p1, p2, p3;
	assign ph0=p0;
	assign ph1=p1;
	assign ph2=p2;
	assign ph3=p3;
	initial begin
		r=0;
		forever begin
			@(posedge clk_in1);
			r = 1;
			p0 <= 0;
			p1 <= 1;
			p2 <= 0;
			p3 <= 0;
			#1.25 r=0;

			#1.25 r=1;
			p0 <= 0;
			p1 <= 0;
			p2 <= 1;
			p3 <= 0;
			#1.25 r=0;

			#1.25 r=1;
			p0 <= 0;
			p1 <= 0;
			p2 <= 0;
			p3 <= 1;
			#1.25 r=0;
			#1.25 r=1;
			p0 <= 1;
			p1 <= 0;
			p2 <= 0;
			p3 <= 0;
			#1.25 r=0;
		end
	end
endmodule
`endif
`else
module clockgen_simple(input clk_in, output clk);
	assign clk = clk_in;
endmodule
`endif

`ifdef NOTDEF
module ic1_data(input [5:0]addra,
                input [5:0]addrb,
                input clka,
                input clkb,
                input [511:0]dina,
                input [511:0]dinb,
                output [511:0]douta,
                output [511:0]doutb,
		input wea,
		input web);

	reg 	[512-1:0]mem[0:63];


        reg [6-1:0]r_addra;
        reg [6-1:0]r_addrb;
	always @(posedge clka)
		r_addra <= addra;
	always @(posedge clkb)
		r_addrb <= addrb;
	always @(posedge clka)
	if (wea)
		mem[addra] <= dina;

	// assum clka==clkb
	always @(posedge clkb)
	if (web)
		mem[addrb] <= dinb;

	reg [512-1:0]outa;
	assign douta = outa;
	always @(*)
	if (clka)
		outa = mem[r_addra];

	reg [512-1:0]outb;
	assign doutb = outb;
	always @(*)
	if (clkb)
		outb = mem[r_addrb];

endmodule

module ic1_tags(input [5:0]addra,
                input [5:0]addrb,
                input clka,
                input clkb,
                input [43:0]dina,
                input [43:0]dinb,
                output [43:0]douta,
                output [43:0]doutb,
		input wea,
		input web);

	reg 	[44-1:0]mem[0:63];


        reg [6-1:0]r_addra;
        reg [6-1:0]r_addrb;
	always @(posedge clka)
		r_addra <= addra;
	always @(posedge clkb)
		r_addrb <= addrb;
	always @(posedge clka)
	if (wea)
		mem[addra] <= dina;

	// assum clka==clkb
	always @(posedge clkb)
	if (web)
		mem[addrb] <= dinb;

	reg [44-1:0]outa;
	assign douta = outa;
	always @(*)
	if (clka)
		outa = mem[r_addra];

	reg [44-1:0]outb;
	assign doutb = outb;
	always @(*)
	if (clkb)
		outb = mem[r_addrb];

endmodule
`endif

module tc2_combined(input [7:0]addra,
                input clka,
                input [79:0]dina,
                output [79:0]douta,
		input wea);

	reg 	[80-1:0]mem[0:255];


        reg [8-1:0]r_addra;
	always @(posedge clka)
		r_addra <= addra;
	always @(posedge clka)
	if (wea)
		mem[addra] <= dina;

	reg [80-1:0]outa;
	assign douta = outa;
	always @(*)
	if (clka)
		outa = mem[r_addra];


endmodule

module mul32(input clk, input [31:0]a, input [31:0]b, output[63:0]p);


	reg [63:0]pp[0:6];
	assign p = pp[0];
	wire unsigned [63:0]ua={32'b0,a};
	wire unsigned [63:0]ub={32'b0,b};
	always @(posedge clk)
 		pp[0] <= ua*ub;
//	genvar I;
//	generate
//		for (I = 1; I < 1; I=I+1) begin
//			always @(posedge clk)
 //				pp[I] <= pp[I-1];
//		end
//	endgenerate
endmodule

module smul32(input clk, input [31:0]a, input [31:0]b, output[63:0]p);

	// 7 clock delay

	reg signed [63:0]pp[0:6];
	assign p = pp[0];
	wire signed [63:0]sa = {{32{a[31]}},a};
	wire signed [63:0]sb = {{32{b[31]}},b};
	always @(posedge clk)
 		pp[0] <= sa*sb;
//	genvar I;
//	generate
//		for (I = 1; I < 7; I=I+1) begin
//			always @(posedge clk)
 //				pp[I] <= pp[I-1];
//		end
//	endgenerate
endmodule
module sumul32(input clk, input [31:0]a, input [31:0]b, output[63:0]p);

	// 7 clock delay

	reg [63:0]pp[0:6];
	assign p = pp[0];
	wire signed [63:0]sa = {{32{a[31]}},a};
	wire unsigned [63:0]ub = {32'b0,b};
	always @(posedge clk)
 		pp[0] <= sa*ub;
//	genvar I;
//	generate
//		for (I = 1; I < 7; I=I+1) begin
//			always @(posedge clk)
 //				pp[I] <= pp[I-1];
//		end
//	endgenerate
endmodule

module mul64(input clk, input [63:0]a, input [63:0]b, output[127:0]p);

	// 7 clock delay

	reg [127:0]pp[0:6];
	assign p = pp[0];
	wire unsigned [127:0]ua={64'b0,a};
	wire unsigned [127:0]ub={64'b0,b};
	always @(posedge clk)
 		pp[0] <= ua*ub;
//	genvar I;
//	generate
//		for (I = 1; I < 1; I=I+1) begin
//			always @(posedge clk)
 //				pp[I] <= pp[I-1];
//		end
//	endgenerate
endmodule

module smul64(input clk, input [63:0]a, input [63:0]b, output[127:0]p);

	// 7 clock delay

	reg signed [127:0]pp[0:6];
	assign p = pp[0];
	wire signed [127:0]sa = {{64{a[63]}},a};
	wire signed [127:0]sb = {{64{b[63]}},b};
	always @(posedge clk)
 		pp[0] <= sa*sb;
//	genvar I;
//	generate
//		for (I = 1; I < 7; I=I+1) begin
//			always @(posedge clk)
 //				pp[I] <= pp[I-1];
//		end
//	endgenerate
endmodule
module sumul64(input clk, input [63:0]a, input [63:0]b, output[127:0]p);

	// 7 clock delay

	reg [127:0]pp[0:6];
	assign p = pp[0];
	wire signed [127:0]sa = {{64{a[63]}},a};
	wire unsigned [127:0]ub = {64'b0,b};
	always @(posedge clk)
 		pp[0] <= sa*ub;
//	genvar I;
//	generate
//		for (I = 1; I < 7; I=I+1) begin
//			always @(posedge clk)
 //				pp[I] <= pp[I-1];
//		end
//	endgenerate
endmodule
`ifdef NOTDEF
module dc1_data(input [5:0]addra,
                input [5:0]addrb,
                input clka,
                input clkb,
                input [511:0]dina,
                input [511:0]dinb,
                output [511:0]douta,
                output [511:0]doutb,
		input [63:0]wea,
		input [63:0]web);



        reg [6-1:0]r_addra;
        reg [6-1:0]r_addrb;
	always @(posedge clka)
		r_addra <= addra;
	always @(posedge clkb)
		r_addrb <= addrb;
/* verilator lint_off MULTIDRIVEN */
	reg 	[512-1:0]mem[0:63];
	generate

		genvar I;
		for (I =0; I <64; I=I+1) begin
			always @(posedge clka)
			if (wea[I])
				mem[addra][I*8+7:I*8] <= dina[I*8+7:I*8];

			always @(posedge clkb)
			if (web[I])
				mem[addrb][I*8+7:I*8] <= dinb[I*8+7:I*8];
		end

	endgenerate
/* verilator lint_on MULTIDRIVEN */

	reg [512-1:0]outa;
	assign douta = outa;
	always @(*)
	if (clka)
		outa = mem[r_addra];

	reg [512-1:0]outb;
	assign doutb = outb;
	always @(*)
	if (clkb)
		outb = mem[r_addrb];

endmodule

module dc1_tags(input [5:0]addra,
                input [5:0]addrb,
                input clka,
                input clkb,
                input [43:0]dina,
                input [43:0]dinb,
                output [43:0]douta,
                output [43:0]doutb,
		input wea,
		input web);

	reg 	[44-1:0]mem[0:63];


        reg [6-1:0]r_addra;
        reg [6-1:0]r_addrb;
	always @(posedge clka)
		r_addra <= addra;
	always @(posedge clkb)
		r_addrb <= addrb;
	always @(posedge clka)
	if (wea)
		mem[addra] <= dina;

	// assum clka==clkb
//	always @(posedge clkb)
	//if (web)
		//mem[addrb] <= dinb;

	reg [44-1:0]outa;
	assign douta = outa;
	always @(*)
	if (clka)
		outa = mem[r_addra];

	reg [44-1:0]outb;
	assign doutb = outb;
	always @(*)
	if (clkb)
		outb = mem[r_addrb];

endmodule
`endif
module sd_in_fifo(
	input		reset,
	input 		wr_clk,
	input  		wr_en,
	input	 [63:0]din,
	output		full,

	input		rd_clk,
	input		rd_en,
	output		empty,
	output    [63:0]dout
	);

	reg r_empty;
	reg r_full;
	assign full=r_full;
	assign empty = r_empty;

	reg [63:0]r_mem[0:(256/(64/8))-1];
	reg [$clog2((256/(64/8)))-1:0]r_inp;
	reg [$clog2((256/(64/8)))-1:0]r_outp;

	assign dout=r_mem[r_outp];

	wire [$clog2((256/(64/8)))-1:0]in_inc = r_inp+1;
	always @(posedge wr_clk) 
	if (reset) begin
		r_inp <= 0;
		r_full <= 0;
	end else begin
		if (wr_en) begin
			r_mem[r_inp] <= din;
			r_inp <= in_inc;
			r_full <= in_inc == r_outp;
		end else begin
			r_full <= r_full&&(r_inp==r_outp);
		end
	end

	wire [$clog2((256/(64/8)))-1:0]out_inc = r_outp+1;
	always @(posedge rd_clk) 
	if (reset) begin
		r_outp <= 0;
		r_empty <= 1;
	end else begin
		if (rd_en) begin
			r_outp <= out_inc;
			r_empty <= (out_inc == r_inp);
		end else begin
			r_empty <= r_empty&&(r_inp==r_outp);
		end
	end
	

endmodule

module sd_out_fifo(
	input		reset,
	input 		wr_clk,
	input  		wr_en,
	input	  [63:0]din,
	output		full,

	input		rd_clk,
	input		rd_en,
	output		empty,
	output    [63:0]dout
	);

	reg r_empty;
	reg r_full;
	assign full=r_full;
	assign empty = r_empty;

	reg [63:0]r_mem[0:(256/(64/8))-1];
	reg [$clog2((256/(64/8)))-1:0]r_inp;
	reg [$clog2((256/(64/8)))-1:0]r_outp;

	assign dout=r_mem[r_outp];

	wire [$clog2((256/(64/8)))-1:0]in_inc = r_inp+1;
	always @(posedge wr_clk) 
	if (reset) begin
		r_inp <= 0;
		r_full <= 0;
	end else begin
		if (wr_en) begin
			r_mem[r_inp] <= din;
			r_inp <= in_inc;
			r_full <= (in_inc == r_outp);
		end else begin
			r_full <= r_full&&(r_inp==r_outp);
		end
	end

	wire [$clog2((256/(64/8)))-1:0]out_inc = r_outp+1;
	always @(posedge rd_clk) 
	if (reset) begin
		r_outp <= 0;
		r_empty <= 1;
	end else begin
		if (rd_en) begin
			r_outp <= out_inc;
			r_empty <= out_inc == r_inp;
		end else begin
			r_empty <= r_empty&&(r_inp==r_outp);
		end
	end
	

endmodule
module RAM64M 
       (input [5:0]ADDRA,
        input [5:0]ADDRB,
        input [5:0]ADDRC,
        input [5:0]ADDRD,
        input DIA,
        input DIB,
        input DIC,
        input DID,
        output DOA,
        output DOB,
        output DOC,
        output DOD,
        input WCLK,
        input WE);

	parameter INIT_A = 64'b0;
	parameter INIT_B = 64'b0;
	parameter INIT_C = 64'b0;
	parameter INIT_D = 64'b0;
	parameter IS_WCLK_INVERTED=0;

	reg [63:0]r_0;
	reg [63:0]r_1;
	reg [63:0]r_2;
	reg [63:0]r_3;
	assign DOA = r_0[ADDRA];
	assign DOB = r_1[ADDRB];
	assign DOC = r_2[ADDRC];
	assign DOD = r_3[ADDRD];

	always @(posedge WCLK)
	if (WE) begin
		r_0[ADDRD] <= DIA;
		r_1[ADDRD] <= DIB;
		r_2[ADDRD] <= DIC;
		r_3[ADDRD] <= DID;
	end

endmodule
module HARD_SYNC(
    input   CLK,
    input   DIN,
    output  DOUT);

    parameter LATENCY=2;

    reg [LATENCY-1:0]r_sync;
    assign DOUT = r_sync[LATENCY-1];

    always @(posedge CLK)
        r_sync <= {r_sync[LATENCY-2:0],DIN};

endmodule

`endif
