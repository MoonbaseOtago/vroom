// UART core WISHBONE interface 
//
// Author: Jacob Gorban   (jacob.gorban@flextronicssemi.com)
// Company: Flextronics Semiconductor
//
// Releases:
//              1.1     First release
//

`include "timescale.v"

module UART_wb (clk,
        wb_rst_i, 
	//wb_dat_i, wb_dat_o, wb_addr_i,
	wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, 
        //int_o,
	we_o // Write enable output for the core
	//dat_i, dat_o, addr_i
	
        );

input				clk;

// WISHBONE interface	
input				wb_rst_i;
//input   [`ADDR_WIDTH-1:0]	wb_addr_i;
//input   [7:0]			wb_dat_i;
//output  [7:0]			wb_dat_o;
input				wb_we_i;
input				wb_stb_i;
input				wb_cyc_i;
output				wb_ack_o;
//output				int_o;
output				we_o;
//output	[`ADDR_WIDTH-1:0]	addr_i;
//output	[7:0]			dat_i;

reg				we_o;
reg				wb_ack_o;
//reg	[7:0]			wb_dat_i;
//reg	[7:0]			wb_dat_o;
//reg	[`ADDR_WIDTH-1:0]	wb_addr_i;
always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i == 1)
	begin
		we_o <= #1 0;
		wb_ack_o <= #1 0;
	end
	else
	begin
		we_o <= #1 wb_we_i & wb_cyc_i & wb_stb_i; //WE for registers	
		wb_ack_o <= #1 wb_stb_i & wb_cyc_i; // 1 clock wait state on all transfers
	end
end

endmodule