module bootrom0(input [8:0]addr, output [127:0]data);
	reg [127:0]rdata;assign data=rdata;
	always @(*)
	case (addr) // synthesis full_case parallel_case
	9'h0: rdata = 128'h44010803006300137313000eb3037ef9;
	9'h1: rdata = 128'h027eb82313fd13820010039b43017ef5;
	9'h2: rdata = 128'h55fdfded8989010eb58302aeb4234505;
	9'h3: rdata = 128'h0585fe859be30585000ebe03000eb383;
	9'h4: rdata = 128'hfe559be30585000eb503000eb50342c1;
	9'h5: rdata = 128'h029eb8230083d49345050405020e0b63;
	9'h6: rdata = 128'h0593fded8989010eb5831e7d02aeb423;
	9'h7: rdata = 128'hf9f515fd03a100c3b023000eb6030200;
	9'h8: rdata = 128'h7581f14025730000100fbf41fc0e1ce3;
	9'h9: rdata = 128'h000100010000006734f6061b49425637;

	endcase
endmodule
