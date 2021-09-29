module main;

	parameter RV=64;
	reg reset, clk;
	reg sz, sub, mul;
	reg [2:0]rnd;
	reg [63:0]in_1, in_2;
	wire exception;
	wire [63:0]res;
	wire exception_mul;
	wire [63:0]res_mul;

	//
	// a - 32bits
	// b - 32bits
	// op - 000 add 001 sub
	// rnd - 00 nearest - even
	// ref - 32bits

	initial begin
		int f, x;
		reg dbl;
		reg [11:0]op;
		reg [7:0]rn;
		reg [63:0]r;
		$dumpfile("fpt.vcd");
		$dumpvars;
		reset = 1;
		#5
		clk = 0; #5 clk = 1; #5
		clk = 0; #5 clk = 1; #5
		if ($test$plusargs ("m")) begin
			if ($test$plusargs ("d")) begin
				sz = 1;
				f = $fopen("fp_mul_test_64.txt", "r");
			end else begin
				sz = 0;
				f = $fopen("fp_mul_test_32.txt", "r");
			end
		end else begin
			if ($test$plusargs ("d")) begin
				sz = 1;
				f = $fopen("fp_add_test_64.txt", "r");
			end else begin
				sz = 0;
				f = $fopen("fp_add_test_32.txt", "r");
			end
		end
		forever begin
			x = $fscanf(f, "%x\n", in_1);
			if (x<=0) begin
				$display("DONE");
				$finish;
			end
			x = $fscanf(f, "%x\n", in_2);
			x = $fscanf(f, "%b\n", op);
			x = $fscanf(f, "%b\n", rn);
			x = $fscanf(f, "%x\n\n", r);
			if (!sz) begin
				in_1[63:32] = 32'hffff_ffff;
				in_2[63:32] = 32'hffff_ffff;
			end
			case (rn) // synthesis full_case parallel_case
			0: rnd = 0;
			1: rnd = 1;
			2: rnd = 3;
			3: rnd = 2;
			endcase		
			sub = 0;
			mul = 0;
			case (op) // synthesis full_case parallel_case
			0: sub = 0;
			1: sub = 1;
			2: mul = 1;
			default: begin sub = 1'bx; mul = 1'bx; end
			endcase		
			clk = 0; #5 clk = 1; #5
			clk = 0; #5 clk = 1; #5
			if (mul) begin
				clk = 0; #5 clk = 1; #5
				if (sz) begin
					if (exception_mul) begin
						$display("%h%s%h = %h EXCEPTION", in_1, "*", in_2, r);
					end else
					if (r !== res_mul) begin
						$display("%h%s%h = %h FAIL (got %h)", in_1, "*", in_2, r, res_mul); 
						$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[63], res_mul[63], r[62:52], res_mul[62:52], r[51:0], res_mul[51:0], rnd);
						$finish;
					end else begin
						$display("%h%s%h = %h OK", in_1, "*", in_2, res_mul);  
					end
				end else begin
					if (exception_mul) begin
						$display("%h%s%h = %h EXCEPTION", in_1[31:0], "*", in_2[31:0], r[31:0]);
					end else
					if (res_mul[63:32] != 32'hffff_ffff) begin
						$display("%h%s%h = %h notfp32 - %h", in_1[31:0], "*", in_2[31:0], r[31:0], res_mul);
						$finish;
					end else
					if (r[31:0] !== res_mul[31:0]) begin
						$display("%h%s%h = %h FAIL (got %h)", in_1[31:0], "*", in_2[31:0], r[31:0], res_mul[31:0]); 
						$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[31], res_mul[31], r[30:23], res_mul[30:23], r[22:0], res_mul[22:0], rnd);
						$finish;
					end else begin
						$display("%h%s%h = %h OK", in_1[31:0], "*", in_2[31:0], res_mul[31:0]);  
					end
				end
			end else 
			if (sz) begin
				if (exception) begin
					$display("%h%s%h = %h EXCEPTION", in_1, sub?"-":"+", in_2, r);
				end else
				if (r !== res) begin
					$display("%h%s%h = %h FAIL (got %h)", in_1, sub?"-":"+", in_2, r, res); 
					$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[63], res[63], r[62:52], res[62:52], r[51:0], res[51:0], rnd);
					$finish;
				end else begin
					$display("%h%s%h = %h OK", in_1, sub?"-":"+", in_2, res);  
				end
			end else begin
				if (exception) begin
					$display("%h%s%h = %h EXCEPTION", in_1[31:0], sub?"-":"+", in_2[31:0], r[31:0]);
				end else
				if (res[63:32] != 32'hffff_ffff) begin
					$display("%h%s%h = %h notfp32 - %h", in_1[31:0], sub?"-":"+", in_2[31:0], r[31:0], res);
					$finish;
				end else
				if (res[31:0] !== r[31:0]) begin
					$display("%h%s%h = %h FAIL (got %h)", in_1[31:0], sub?"-":"+", in_2[31:0], r[31:0], res[31:0]); 
					$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[31], res[31], r[30:23], res[30:23], r[22:0], res[22:0], rnd);
					$finish;
				end else begin
					$display("%h%s%h = %h OK", in_1[31:0], sub?"-":"+", in_2[31:0], res[31:0]);  
				end
			end
		end
	end
		

	fp_add_sub #(.RV(RV))fp_add(
		.reset(reset), 
		.clk(clk),
        	.sz(sz),
        	.sub(sub),
        	.rnd(rnd),
        	.in_1(in_1),
        	.in_2(in_2),
        	.exception(exception),
        	.res(res));

	fp_mul #(.RV(RV))fpm(
		.reset(reset), 
		.clk(clk),
        	.sz(sz),
        	.rnd(rnd),
        	.in_1(in_1),
        	.in_2(in_2),
		.in_3(in_3),
		.fmuladd(1'b0),
		.fmulsub(1'b0),
		.fmulsign(1'b0),
        	.exception(exception_mul),
        	.res(res_mul));

endmodule
