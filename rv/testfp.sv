module main;

	parameter RV=64;
	reg reset, clk;
	reg sub, mul;
	reg div, issqrt, div_start;
	reg [1:0]sz;	// 0=32-bit 1=64-bit 2=16-bit
	reg [2:0]rnd;
	reg [63:0]in_1, in_2, in_3;
	reg fmuladd, fmulsub, fmulsign;
	wire [4:0]exceptions;
	wire [63:0]res;
	wire [4:0]exception_mul;
	wire [63:0]res_mul;
	wire [63:0]res_div;
	wire [4:0]exception_div;
	wire valid_div;
	string file_name;
	integer in;
	integer count;

	wire sig_exception = 0;
	wire exception=0;

	//	old format   not +n
	// a - 32bits
	// b - 32bits
	// op - 000 add 001 sub
	// rnd - 00 nearest - even
	// ref - 32bits

	//  +n
	//  O op	- 0 add, 1 sub, 2 mul, 3 a*b+c, 4 a*b-c 5 -(a*b)+c 6 -(a*b)-c
	//			7 div 8 sqrt
	//  R rnd
	//  S sz
	//  a b c flags

	initial begin
		int line, f, x;
		reg dbl;
		reg [11:0]op;
		reg [7:0]rn;
		reg [7:0]flags;
		reg [63:0]r;
		string op1, op2;
		if (! $test$plusargs ("n")) begin
			$dumpfile("fpt.vcd");
			$dumpvars;
		end
		div_start = 0;
		reset = 1;
		in_3 = 0;
		fmuladd = 0;
		#5
		clk = 0; #5 clk = 1; #5
		reset = 0;
		clk = 0; #5 clk = 1; #5
		if ($test$plusargs ("t")) begin
			if ($value$plusargs ("t=%s", file_name)) begin
				f = $fopen(file_name, "r");
				if (!f) begin
					$display("ERR: can't open test file %s", file_name);
					$finish;
				end
			end else begin
				$display("ERR: no test file specified with +t=name");
				$finish;
			end
			line = 0;
			in = 0;
			while (in >=0  && !$feof(f)) begin
				line = line+1;
				//x=$fscanf(f, "%s", in);
				in = $fgetc(f);
				if (in >= 0) 
				if (in == "o") begin		// op 0=add 1=sub 2=mul 3=muladd
					x = $fscanf(f, " %d", op);
					op1 = "";
					op2 = "";
					div = 0;
					issqrt = 0;
					case (op) // synthesis full_case parallel_case
					0: begin sub = 0; mul = 0; end
					1: begin sub = 1; mul = 0; end
					2: begin mul = 1; sub = 0; fmuladd = 0; end
					3: begin mul = 1; sub = 0; fmuladd = 1; fmulsub = 0; fmulsign = 0; op1=""; op2="+"; end
					4: begin mul = 1; sub = 0; fmuladd = 1; fmulsub = 1; fmulsign = 0; op1=""; op2="-"; end
					5: begin mul = 1; sub = 0; fmuladd = 1; fmulsub = 0; fmulsign = 1; op1="-("; op2=")+"; end
					6: begin mul = 1; sub = 0; fmuladd = 1; fmulsub = 1; fmulsign = 1; op1="-("; op2=")-"; end
					7: begin div=1; mul = 0; sub = 0; fmuladd = 0; fmulsub = 0; fmulsign = 0; op1=""; op2="/"; end
					8: begin div=1; issqrt=1; mul = 0; sub = 0; fmuladd = 0; fmulsub = 0; fmulsign = 0; op1=""; op2="~"; end
					default: begin sub = 1'bx; mul = 1'bx;  fmuladd = 1'bx; end
					endcase		
					in = $fgetc(f);
				end else
				if (in == "r") begin		// rounding 0-7
					x = $fscanf(f, " %d", rn);
					case (rn) // synthesis full_case parallel_case
					0: rnd = 0;
					1: rnd = 1;
					2: rnd = 2;
					3: rnd = 3;
					4: rnd = 4;
					endcase		
					in = $fgetc(f);
				end else
				if (in == "s") begin		// size 0=32 1=64 2=16
					count = $fscanf(f, " %d", sz);
					in = $fgetc(f);
				end else begin
					x = $ungetc(in, f);
					if (op == 8) begin
						x = $fscanf(f, "%x %x %x", in_1, r, flags);
					end else 
					if (op >= 3 && op <= 6) begin
						x = $fscanf(f, "%x %x %x %x %x", in_1, in_2, in_3, r, flags);
					end else begin
						x = $fscanf(f, "%x %x %x %x", in_1, in_2, r, flags);
					end
					in = $fgetc(f);
					if (x < 3) begin
						$display("BAD input line #%d '%c' %x", line, in, in);
						$finish;
					end
					casez (sz) 
					2'b1?:	begin
							in_1 = {~48'h0, in_1[15:0]};
							in_2 = {~48'h0, in_2[15:0]};
							in_3 = {~48'h0, in_3[15:0]};
							r = {~48'h0, r[15:0]};
						end
					2'b?1:;
					2'b00:	begin
							in_1 = {~32'h0, in_1[31:0]};
							in_2 = {~32'h0, in_2[31:0]};
							in_3 = {~32'h0, in_3[31:0]};
							r = {~32'h0, r[31:0]};
						end
					endcase
					if (div) begin
						clk = 0; div_start=1; #5 clk = 1; #5
						while (!valid_div) begin
							clk = 0; div_start = 0; #5  clk = 1; #5;
						end
						if (!issqrt) begin
							casez (sz) 
							2'b1?:	if (sig_exception && exception_div) begin
									$display("%h%s%h = %h EXCEPTION", in_1[15:0], "/", in_2[15:0], r[15:0]);
								end else
								if (res_div[63:16] != 48'hffff_ffff_ffff) begin
									$display("%h%s%h = %h notfp16 - %h", in_1[15:0], "/", in_2[15:0], r[15:0], res_div);
									$finish;
								end else
								if (r[15:0] !== res_div[15:0]) begin
									$display("%h%s%h = %h FAIL (got %h)", in_1[15:0], "/", in_2[15:0], r[15:0], res_div[15:0]); 
									$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[15], res_div[15], r[14:10], res_div[14:10], r[9:0], res_div[9:0], rnd);
									$finish;
								end else begin
									$display("%h%s%h = %h OK", in_1[15:0], "/", in_2[15:0], res_div[15:0]);  
								end
							2'b?1:	if (sig_exception && exception_div) begin
									$display("%h%s%h = %h EXCEPTION", in_1, "/", in_2, r);
								end else
								if (r !== res_div) begin
									$display("%h%s%h = %h FAIL (got %h)", in_1, "/", in_2, r, res_div); 
									$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[63], res_div[63], r[62:52], res_div[62:52], r[51:0], res_div[51:0], rnd);
									$finish;
								end else begin
									$display("%h%s%h = %h OK", in_1, "/", in_2, res_div);  
								end
							2'b00:	if (sig_exception && exception_div) begin
									$display("%h%s%h = %h EXCEPTION", in_1[31:0], "/", in_2[31:0], r[31:0]);
								end else
								if (res_div[63:32] != 32'hffff_ffff) begin
									$display("%h%s%h = %h notfp32 - %h", in_1[31:0], "/", in_2[31:0], r[31:0], res_div);
									$finish;
								end else
								if (r[31:0] !== res_div[31:0]) begin
									$display("%h%s%h = %h FAIL (got %h)", in_1[31:0], "/", in_2[31:0], r[31:0], res_div[31:0]); 
									$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[31], res_div[31], r[30:23], res_div[30:23], r[22:0], res_div[22:0], rnd);
									$finish;
								end else begin
									$display("%h%s%h = %h OK", in_1[31:0], "/", in_2[31:0], res_div[31:0]);  
								end
							endcase
						end else begin
							casez (sz) 
							2'b1?:	if (sig_exception && exception_div) begin
									$display("sqrt %h = %h EXCEPTION", in_1[15:0], r[15:0]);
								end else
								if (res_div[63:16] != 48'hffff_ffff_ffff) begin
									$display("sqrt %h = %h notfp16 - %h", in_1[15:0], r[15:0], res_div);
									$finish;
								end else
								if (r[15:0] !== res_div[15:0]) begin
									$display("sqrt %h = %h FAIL (got %h)", in_1[15:0], r[15:0], res_div[15:0]); 
									$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[15], res_div[15], r[14:10], res_div[14:10], r[9:0], res_div[9:0], rnd);
									$finish;
								end else begin
									$display("sqrt %h = %h OK", in_1[15:0], res_div[15:0]);  
								end
							2'b?1:	if (sig_exception && exception_div) begin
									$display("sqrt %h = %h EXCEPTION", in_1, r);
								end else
								if (r !== res_div) begin
									$display("sqrt %h = %h FAIL (got %h)", in_1, r, res_div); 
									$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[63], res_div[63], r[62:52], res_div[62:52], r[51:0], res_div[51:0], rnd);
									$finish;
								end else begin
									$display("sqrt %h = %h OK", in_1, res_div);  
								end
							2'b00:	if (sig_exception && exception_div) begin
									$display("sqrt %h = %h EXCEPTION", in_1[31:0], r[31:0]);
								end else
								if (res_div[63:32] != 32'hffff_ffff) begin
									$display("sqrt %h = %h notfp32 - %h", in_1[31:0], r[31:0], res_div);
									$finish;
								end else
								if (r[31:0] !== res_div[31:0]) begin
									$display("sqrt %h = %h FAIL (got %h)", in_1[31:0], r[31:0], res_div[31:0]); 
									$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[31], res_div[31], r[30:23], res_div[30:23], r[22:0], res_div[22:0], rnd);
									$finish;
								end else begin
									$display("sqrt %h = %h OK", in_1[31:0], res_div[31:0]);  
								end
							endcase
						end
					end else
					if (mul) begin
						clk = 0; #5 clk = 1; #5
						clk = 0; #5 clk = 1; #5
						if (!fmuladd) begin
							casez (sz) 
							2'b1?:	if (sig_exception && exception_mul) begin
									$display("%h%s%h = %h EXCEPTION", in_1[15:0], "*", in_2[15:0], r[15:0]);
								end else
								if (res_mul[63:16] != 48'hffff_ffff_ffff) begin
									$display("%h%s%h = %h notfp16 - %h", in_1[15:0], "*", in_2[15:0], r[15:0], res_mul);
									$finish;
								end else
								if (r[15:0] !== res_mul[15:0]) begin
									$display("%h%s%h = %h FAIL (got %h)", in_1[15:0], "*", in_2[15:0], r[15:0], res_mul[15:0]); 
									$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[15], res_mul[15], r[14:10], res_mul[14:10], r[9:0], res_mul[9:0], rnd);
									$finish;
								end else begin
									$display("%h%s%h = %h OK", in_1[15:0], "*", in_2[15:0], res_mul[15:0]);  
								end
							2'b?1:	if (sig_exception && exception_mul) begin
									$display("%h%s%h = %h EXCEPTION", in_1, "*", in_2, r);
								end else
								if (r !== res_mul) begin
									$display("%h%s%h = %h FAIL (got %h)", in_1, "*", in_2, r, res_mul); 
									$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[63], res_mul[63], r[62:52], res_mul[62:52], r[51:0], res_mul[51:0], rnd);
									$finish;
								end else begin
									$display("%h%s%h = %h OK", in_1, "*", in_2, res_mul);  
								end
							2'b00:	if (sig_exception && exception_mul) begin
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
							endcase
						end else begin
							casez (sz) 
							2'b1?:	if (sig_exception && exception_mul) begin
									$display("%s%h%s%h%s%h = %h EXCEPTION", op1, in_1[15:0], "*", in_2[15:0], op2, in_3[15:0],  r[15:0]);
								end else
								if (res_mul[63:16] != 48'hffff_ffff_ffff) begin
									$display("%s%h%s%h%s%h = %h notfp16 - %h", op1, in_1[15:0], "*", in_2[15:0], op2, in_3[15:0], r[15:0], res_mul);
									$finish;
								end else
								if (r[15:0] !== res_mul[15:0]) begin
									$display("%s%h%s%h%s%h = %h FAIL (got %h)",  op1, in_1[15:0], "*", in_2[15:0], op2, in_3[15:0], r[15:0], res_mul[15:0]); 
									$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[15], res_mul[15], r[14:10], res_mul[14:10], r[9:0], res_mul[9:0], rnd);
									$finish;
								end else begin
									$display("%s%h%s%h%s%h = %h OK", op1, in_1[15:0], "*", in_2[15:0], op2, in_3[15:0], res_mul[15:0]);  
								end
							2'b?1:	if (sig_exception && exception_mul) begin
									$display("%s%h%s%h%s%h = %h EXCEPTION", op1, in_1, "*", in_2, op2, in_3, r);
								end else
								if (r !== res_mul) begin
									$display("%s%h%s%h%s%h = %h FAIL (got %h)", op1, in_1, "*", in_2, op2, in_3, r, res_mul); 
									$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[63], res_mul[63], r[62:52], res_mul[62:52], r[51:0], res_mul[51:0], rnd);
									$finish;
								end else begin
									$display("%s%h%s%h%s%h = %h OK", op1, in_1, "*", in_2, op2, in_3, res_mul);  
								end
							2'b00:	if (sig_exception && exception_mul) begin
									$display("%s%h%s%h%s%h = %h EXCEPTION", op1, in_1[31:0], "*", in_2[31:0], op2, in_3[31:0], r[31:0]);
								end else
								if (res_mul[63:32] != 32'hffff_ffff) begin
									$display("%s%h%s%h%s%h = %h notfp32 - %h", op1, in_1[31:0], "*", in_2[31:0], op2, in_3[31:0], r[31:0], res_mul);
									$finish;
								end else
								if (r[31:0] !== res_mul[31:0]) begin
									$display("%s%h%s%h%s%h = %h FAIL (got %h)", op1, in_1[31:0], "*", in_2[31:0], op2, in_3[31:0], r[31:0], res_mul[31:0]); 
									$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[31], res_mul[31], r[30:23], res_mul[30:23], r[22:0], res_mul[22:0], rnd);
									$finish;
								end else begin
									$display("%s%h%s%h%s%h = %h OK", op1, in_1[31:0], "*", in_2[31:0], op2, in_3[31:0], res_mul[31:0]);  
								end
							endcase
						end
					end else begin
						clk = 0; #5 clk = 1; #5
						casez (sz) 
						2'b1?: if (sig_exception && exception) begin
								$display("%h%s%h = %h EXCEPTION", in_1[15:0], sub?"-":"+", in_2[15:0], r[15:0]);
							end else
							if (res[63:16] != 48'hffff_ffff_ffff) begin
								$display("%h%s%h = %h notfp16 - %h", in_1[15:0], sub?"-":"+", in_2[15:0], r[15:0], res);
								$finish;
							end else
							if (res[15:0] !== r[15:0]) begin
								$display("%h%s%h = %h FAIL (got %h)", in_1[15:0], sub?"-":"+", in_2[15:0], r[15:0], res[15:0]); 
								$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[15], res[15], r[14:10], res[14:10], r[9:0], res[9:0], rnd);
								$finish;
							end else begin
								$display("%h%s%h = %h OK", in_1[15:0], sub?"-":"+", in_2[15:0], res[15:0]);  
							end
						2'b?1:	if (sig_exception && exception) begin
								$display("%h%s%h = %h EXCEPTION", in_1, sub?"-":"+", in_2, r);
							end else
							if (r !== res) begin
								$display("%h%s%h = %h FAIL (got %h)", in_1, sub?"-":"+", in_2, r, res); 
								$display("(g b) s(%b %b) e(%h %h) m(%h %h) rnd=%d", r[63], res[63], r[62:52], res[62:52], r[51:0], res[51:0], rnd);
								$finish;
							end else begin
								$display("%h%s%h = %h OK", in_1, sub?"-":"+", in_2, res);  
							end
						2'b00: if (sig_exception && exception) begin
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
						endcase
					end
				end
			end
			$display("DONE");
			$finish;
		end else
		if ($test$plusargs ("x")) begin
			sub = 0;
			mul = 0;
			sz = 1;
			fmuladd = 0;
			in_1 = 64'h3FF0000000000000;	// 1
			in_1 = 64'h4000000000000000;	// 2
			in_1 = 64'h4008000000000000;	// 3
			in_2 = 64'h3FF0000000000000;	// 1
			in_2 = 64'h4008000000000000;	// 3
			in_3 = 0;			// 0
			rnd = 0;
			clk = 0; #5 clk = 1; #5
			clk = 0; #5 clk = 1; #5
			clk = 0; #5 clk = 1; #5
			$display("s(%b) e(%h) m(%h) rnd=%d", res_mul[63],res_mul[62:52],res_mul[51:0], rnd);
			in_3 = 64'h3FF0000000000000;	// 1
			clk = 0; #5 clk = 1; #5
			clk = 0; #5 clk = 1; #5
			clk = 0; #5 clk = 1; #5
			$display("s(%b) e(%h) m(%h) rnd=%d", res_mul[63],res_mul[62:52],res_mul[51:0], rnd);
			$finish;
		end else
		if ($test$plusargs ("m")) begin
			if ($test$plusargs ("d")) begin
				sz = 1;
				f = $fopen("fptest/fp_mul_test_64.txt", "r");
			end else begin
				sz = 0;
				f = $fopen("fptest/fp_mul_test_32.txt", "r");
			end
		end else begin
			if ($test$plusargs ("d")) begin
				sz = 1;
				f = $fopen("fptest/fp_add_test_64.txt", "r");
			end else begin
				sz = 0;
				f = $fopen("fptest/fp_add_test_32.txt", "r");
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
			//clk = 0; #5 clk = 1; #5
			clk = 0; #5 clk = 1; #5
			if (mul) begin
				clk = 0; #5 clk = 1; #5
				if (sz) begin
					if (sig_exception && exception_mul) begin
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
					if (sig_exception && exception_mul) begin
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
				if (sig_exception && exception) begin
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
				if (sig_exception && exception) begin
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
		.start(1'b1),
        	.sz(sz),
        	.sub(sub),
        	.rnd(rnd),
        	.in_1(in_1),
        	.in_2(in_2),
        	.exceptions(exceptions),
        	.res(res));

	fp_mul #(.RV(RV))fpm(
		.hart(1'b0),
		.start(1'b1),
		.rd(6'b0),
		.reset(reset), 
		.clk(clk),
        	.sz(sz),
        	.rnd(rnd),
        	.in_1(in_1),
        	.in_2(in_2),
		.in_3(in_3),
		.fmuladd(fmuladd),
		.fmulsub(fmulsub),
		.fmulsign(fmulsign),
        	.exceptions(exception_mul),
        	.res(res_mul));

	fp_div #(.RV(RV))fpdiv(
		.hart(1'b0),
		.start(div_start),
		.rd(6'b0),
		.reset(reset), 
		.issqrt(issqrt),
		.clk(clk),
        	.sz(sz),
        	.rnd(rnd),
        	.in_1(in_1),
        	.in_2(in_2),
        	.res(res_div),
		.commit_kill_0(64'b0),
        	.exceptions(exception_div),
		.valid(valid_div),
		.valid_ack(valid_div));

endmodule
