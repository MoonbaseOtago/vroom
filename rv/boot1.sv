module bootrom1(input [8:0]addr, output [127:0]data);
	reg [127:0]rdata;assign data=rdata;
	always @(*)
	case (addr) // synthesis full_case parallel_case
	9'h0: rdata = 128'h00000000000000000001000195024501;

	endcase
endmodule
