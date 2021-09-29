module test;
	parameter NPHYS=56;
	parameter NLDSTQ=8;
	parameter TRANS_ID_SIZE=5;
	parameter TSIZE=5;
	parameter ACACHE_LINE_SIZE=6;
	parameter CACHE_LINE_SIZE=512;

	reg reset, clk;
	reg mem_raddr_req, mem_waddr_req, mem_rdata_ack;
	reg [511:0]mem_wdata;
	reg [55:6]mem_raddr, mem_waddr;
	wire [511:0]mem_rdata;
	wire [4:0]mem_wdata_trans, mem_rdata_trans;
	reg [4:0]mem_waddr_trans, mem_raddr_trans;

	wire	mem_wdata_done, mem_raddr_ack, mem_rdata_req, mem_waddr_ack;
	initial begin
		clk = 0;
		reset = 1;
		mem_raddr_req = 0;
		mem_rdata_ack = 0;
		mem_waddr_req = 0;
		#5 clk = 1; #5 clk = 0;
		#5 clk = 1; #5 clk = 0;
		#5 clk = 1; #5 clk = 0;
		#5 clk = 1; #5 clk = 0;
		reset = 0;
		forever #5 clk = 1; #5 clk = 0;
	end
	reg	sh_cl_clk, sh_cl_reset;
	reg	sh_cl_ddr_awready, sh_cl_ddr_wready, sh_cl_ddr_bvalid, sh_cl_ddr_arready, sh_cl_ddr_rvalid;
	initial begin
		sh_cl_clk = 0; 
		sh_cl_reset = 1;
		sh_cl_ddr_awready = 0;
		sh_cl_ddr_wready = 0;
		sh_cl_ddr_bvalid = 0;
		sh_cl_ddr_arready = 0;
		sh_cl_ddr_rvalid = 0;
		#1 sh_cl_clk = 1; #1 sh_cl_clk = 0;
		#1 sh_cl_clk = 1; #1 sh_cl_clk = 0;
		#1 sh_cl_clk = 1; #1 sh_cl_clk = 0;
		#1 sh_cl_clk = 1; #1 sh_cl_clk = 0;
		sh_cl_reset = 0;
		forever #1 sh_cl_clk = 1; #1 sh_cl_clk = 0;
	end
	wire	cl_sh_ddr_awvalid, cl_sh_ddr_wvalid, cl_sh_ddr_bready, cl_sh_ddr_arvalid, cl_sh_ddr_rready;
	reg [511:0]sh_cl_ddr_rdata;
	wire [511:0]cl_sh_ddr_wdata;
	wire [55:6]cl_sh_ddr_awaddr, cl_sh_ddr_araddr;
	wire [4:0]cl_sh_ddr_arid, cl_sh_ddr_awid;
	reg [4:0]sh_cl_ddr_rid, sh_cl_ddr_bresp;
	reg [1:0]sh_cl_ddr_bresp

		.cl_sh_ddr_awvalid(cl_sh_ddr_awvalid),
		.sh_cl_ddr_awready(sh_cl_ddr_awready),
		.cl_sh_ddr_awaddr(cl_sh_ddr_awaddr),
		.cl_sh_ddr_awid(cl_sh_ddr_awid),

		.cl_sh_ddr_wvalid(cl_sh_ddr_wvalid),
		.sh_cl_ddr_wready(sh_cl_ddr_wready),
		.cl_sh_ddr_wid(cl_sh_ddr_wid),
		.cl_sh_ddr_wdata(cl_sh_ddr_wdata),

        	.sh_cl_ddr_bid(sh_cl_ddr_bresp),
        	.sh_cl_ddr_bresp(sh_cl_ddr_bresp),
        	.sh_cl_ddr_bvalid(sh_cl_ddr_bvalid),
        	.cl_sh_ddr_bready(cl_sh_ddr_bready),

		.cl_sh_ddr_arvalid(cl_sh_ddr_arvalid),
		.sh_cl_ddr_arready(sh_cl_ddr_arready),
		.cl_sh_ddr_arid(cl_sh_ddr_arid),
		.cl_sh_ddr_araddr(cl_sh_ddr_araddr),
		
		.cl_sh_ddr_rready(cl_sh_ddr_rready),
		.sh_cl_ddr_rvalid(sh_cl_ddr_rvalid),
		.sh_cl_ddr_rid(sh_cl_ddr_rid),
		.sh_cl_ddr_rdata(sh_cl_ddr_rdata)

	mem_interface #(.NPHYS(NPHYS), .NLDSTQ(NLDSTQ), .TRANS_ID_SIZE(TRANS_ID_SIZE), .TSIZE(TSIZE), .ACACHE_LINE_SIZE(ACACHE_LINE_SIZE), .CACHE_LINE_SIZE(CACHE_LINE_SIZE))mem(.clk(clk), .reset(reset),
		.mem_raddr(mem_raddr),
		.mem_raddr_ack(mem_raddr_ack),
		.mem_raddr_trans(mem_raddr_trans),
		.mem_raddr_req(mem_raddr_req),
		.mem_rdata(mem_rdata),
		.mem_rdata_trans(mem_rdata_trans),
		.mem_rdata_ack(mem_rdata_ack),
		.mem_rdata_req(mem_rdata_req),
		.mem_waddr(mem_waddr),
		.mem_wdata(mem_wdata),
		.mem_waddr_trans(mem_waddr_trans),
		.mem_waddr_req(mem_waddr_req),
		.mem_waddr_ack(mem_waddr_ack),
		.mem_wdata_trans(mem_wdata_trans),
		.mem_wdata_done(mem_wdata_done) ,

		.sh_cl_clk(sh_cl_clk),
		.sh_cl_reset(sh_cl_reset),
		.cl_sh_ddr_awvalid(cl_sh_ddr_awvalid),
		.sh_cl_ddr_awready(sh_cl_ddr_awready),
		.cl_sh_ddr_awaddr(cl_sh_ddr_awaddr),
		.cl_sh_ddr_awid(cl_sh_ddr_awid),

		.cl_sh_ddr_wvalid(cl_sh_ddr_wvalid),
		.sh_cl_ddr_wready(sh_cl_ddr_wready),
		.cl_sh_ddr_wid(cl_sh_ddr_wid),
		.cl_sh_ddr_wdata(cl_sh_ddr_wdata),

        	.sh_cl_ddr_bid(sh_cl_ddr_bid),
        	.sh_cl_ddr_bresp(sh_cl_ddr_bresp),
        	.sh_cl_ddr_bvalid(sh_cl_ddr_bvalid),
        	.cl_sh_ddr_bready(cl_sh_ddr_bready),

		.cl_sh_ddr_arvalid(cl_sh_ddr_arvalid),
		.sh_cl_ddr_arready(sh_cl_ddr_arready),
		.cl_sh_ddr_arid(cl_sh_ddr_arid),
		.cl_sh_ddr_araddr(cl_sh_ddr_araddr),
		
		.cl_sh_ddr_rready(cl_sh_ddr_rready),
		.sh_cl_ddr_rvalid(sh_cl_ddr_rvalid),
		.sh_cl_ddr_rid(sh_cl_ddr_rid),
		.sh_cl_ddr_rdata(sh_cl_ddr_rdata)
		);

endmodule
