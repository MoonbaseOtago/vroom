/// File:  FIFO_inc.v
/// Author: Jacob Gorban, Flextronics Semiconductor
///
/// This file is FIFO logic. It should be included in your FIFO.
/// A module envelope should be created in the parent file.
/// The reason for creating this in a included module is being able to create custom FIFOs,
/// like modules with different ports or additional logic on the FIFO except the standard, easily

// FIFO parameters
parameter fifo_width = `FIFO_WIDTH;
parameter fifo_depth = `FIFO_DEPTH;
parameter fifo_pointer_w = `FIFO_POINTER_W;
parameter fifo_counter_w = `FIFO_COUNTER_W;

input				clk;
input				wb_rst_i;
input				push;
input				pop;
input	[fifo_width-1:0]	data_in;
output	[fifo_width-1:0]	data_out;
output				overrun;
output				underrun;
output	[fifo_counter_w-1:0]	count;

wire	[fifo_width-1:0]	data_out;

// FIFO itself
reg	[fifo_width-1:0]	fifo[fifo_depth-1:0];

// FIFO pointers
reg	[fifo_pointer_w-1:0]	top;
reg	[fifo_pointer_w-1:0]	bottom;

reg	[fifo_counter_w-1:0]	count;
reg				overrun;
reg				underrun;

wire [fifo_pointer_w-1:0] top_plus_1 = top + 1;

//always @(posedge clk or posedge wb_rst_i) // synchronous FIFO
always @(posedge push or posedge pop or posedge wb_rst_i)  // asynchronous FIFO
begin
	if (wb_rst_i==1)
	begin
		top		<= #1 0;
		bottom		<= #1 0;
		underrun	<= #1 0;
		overrun		<= #1 0;
		count		<= #1 0;
	end
	else
	begin
		case ({push, pop})
//		2'b00 : begin  // this will never happen, really
//				underrun <= #1 0;
//				overrun  <= #1 0;
//	 	        end
		2'b10 : if (count==fifo_depth)  // overrun condition
			begin
				overrun   <= #1 1;
				underrun  <= #1 0;
			end
			else
			begin
				top       <= #1 top_plus_1;
				fifo[top_plus_1] <= #1 data_in;
				underrun  <= #1 0;
				overrun   <= #1 0;
				count     <= #1 count + 1;
			end
		2'b01 : if (~|count)
			begin
				underrun <= #1 1;  // underrun condition
				overrun  <= #1 0;
			end
			else
			begin
				bottom   <= #1 bottom + 1;
				underrun <= #1 0;
				overrun  <= #1 0;
				count	 <= #1 count -1;
			end
		2'b11 : begin
				bottom   <= #1 bottom + 1;
				top       <= #1 top_plus_1;
				fifo[top_plus_1] <= #1 data_in;
				underrun <= #1 0;
				overrun  <= #1 0;
		        end
		endcase
	end
end   // always

always @(posedge clk)
begin
	if (overrun)
		overrun <= #1 0;
	if (underrun)
		underrun <= #1 0;
end


// please note though that data_out is only valid one clock after pop signal
assign data_out = fifo[bottom];