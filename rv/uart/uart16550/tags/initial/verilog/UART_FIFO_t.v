`include "UART_defines.v"

module FIFO_test ();

reg clk;

initial
begin
	clk = 0;
	//#1000 $finish;
end

always
	#5 clk = ~ clk;

wire [4:0] count;
reg [7:0] data_in;
wire [7:0] data_out;
reg push, pop;
reg reset;

integer i,j,d,c;

UART_FIFO f(clk, 
	reset, data_in, data_out,
// Control signals
	push, // push strobe, active high
	pop,   // pop strobe, active high
// status signals
	underrun,
	overrun,
	count

	);

initial 
begin
	#4 reset = 1;
	#10 reset = 0;
	#10 data_in = 1;
	#10 pop = 1;
	#10 pop = 0;
     for ( j=1; j<=2; j=j+1 )
     begin
	$display("Running with j=", j);
	d = j*5;
	for ( i=0 ;i<=17 ;i=i+1 )
	begin
		data_in = i;
		@(posedge clk);
//              if (count!=i-1)
//			$display("Error: @",$time,": Count output error on i= ", i, " ; count = ", count);

		push <= #1 1;
		if (j==2) begin
			@(posedge clk);
			push <= #1 0;
		end
              #2;
		
	end
	push <= #1 0;
	for ( i=0 ;i<=17 ;i=i+1 )
	begin
		@(posedge clk);
		pop <= #1 1 ;
		if (j==2) begin
			@(posedge clk);
			pop <= #1 0;
		end
		c = i<=16 ? i : 16;
//		if (data_out != c) 
//			$display("Error: @",$time,": Data should be ", c, " and not ", data_out);
	end
	pop <= #1 0;
     end
     #1 $finish;
end

endmodule
