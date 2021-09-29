module bootrom1(input [8:0]addr, output [127:0]data);
	reg [127:0]rdata;assign data=rdata;
	always @(*)
	case (addr) // synthesis full_case parallel_case
	9'h0: rdata = 128'h0000001300000013000500e700000513;

	endcase
endmodule
