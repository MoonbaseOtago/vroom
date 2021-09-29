//  UART core registers
//
// Includes transmission and reception tasks
//
// Author: Jacob Gorban   (jacob.gorban@flextronicssemi.com)
// Company: Flextronics Semiconductor
//
// Filename: UART_regs.v
//
// Releases:
//              1.1     First release
//
`include "timescale.v"
`include "UART_defines.v"

`define DL1 7:0
`define DL2 15:8
`define DL3 23:16
`define DL4 31:24

module UART_regs (clk,
	wb_rst_i, wb_addr_i, wb_dat_i, wb_dat_o, wb_we_i,

// registers
	ier, iir, fcr, mcr, lcr, lsr, msr, dl,
// additional signals
	modem_inputs,
	stx_o, srx_i,
	enable,
	rts_o, dtr_o
	);

input		clk;
input		wb_rst_i;
input	[`ADDR_WIDTH-1:0]	wb_addr_i;
input	[7:0]	wb_dat_i;
output	[7:0]	wb_dat_o;
input		wb_we_i;

output	[3:0]	ier;
output	[7:0]	iir;
output	[3:0]	fcr;  /// bits 7,6,2,1 of fcr. Other bits are ignored
output	[4:0]	mcr;
output	[7:0]	lcr;
output	[7:0]	lsr;
output	[7:0]	msr;
output	[31:0]	dl;  // 32-bit divisor latch
output		stx_o;
input		srx_i;

input	[3:0]	modem_inputs;
output		enable;
output		rts_o;
output		dtr_o;

wire	[3:0]	modem_inputs;
reg		enable;
reg		stx_o;
wire		srx_i;

reg	[7:0]	wb_dat_o;

wire	[`ADDR_WIDTH-1:0]	wb_addr_i;
wire	[7:0]	wb_dat_i;


reg	[3:0]	ier;
reg	[7:0]	iir;
reg	[3:0]	fcr;  /// bits 7,6,2,1 of fcr. Other bits are ignored
reg	[4:0]	mcr;
reg	[7:0]	lcr;
reg	[7:0]	lsr;
reg	[7:0]	msr;
reg	[31:0]	dl;  // 32-bit divisor latch

reg	[31:0]	dlc;  // 32-bit divisor latch counter

// Transmitter FIFO signals
wire	[`FIFO_WIDTH-1:0]	tf_data_in;
wire	[`FIFO_WIDTH-1:0]	tf_data_out;
reg				tf_push;
reg				tf_pop;
wire				tf_underrun;
wire				tf_overrun;
wire	[`FIFO_COUNTER_W-1:0]	tf_count;

// Receiver FIFO signals
reg	[`FIFO_REC_WIDTH-1:0]	rf_data_in;
wire	[`FIFO_REC_WIDTH-1:0]	rf_data_out;
reg				rf_push;
reg				rf_pop;
wire				rf_underrun;
wire				rf_overrun;
wire	[`FIFO_COUNTER_W-1:0]	rf_count;
wire				rf_error_bit; // an error (parity or framing) is inside the fifo

reg	[3:0]			trigger_level; // trigger level of the receiver FIFO

wire		dlab;			   // divisor latch access bit
wire		cts_i, dsr_i, ri_i, dcd_i; // modem status bits
wire		loopback;		   // loopback bit (MCR bit 4)
wire		cts, dsr, ri, dcd;	   // effective signals (considering loopback)
wire		rts_o, dtr_o;		   // modem control outputs

//
// ASSINGS
//
assign {cts_i, dsr_i, ri_i, dcd_i} = modem_inputs;
assign {cts, dsr, ri, dcd} = loopback ? {mcr[`MC_RTS],mcr[`MC_DTR],mcr[`MC_OUT1],mcr[`MC_OUT2]}
		 : ~{cts_i,dsr_i,ri_i,dcd_i};

assign dlab = lcr[`LC_DL];
assign tf_data_in = wb_dat_i;
assign loopback = mcr[4];

// assign modem outputs
assign	rts_o = mcr[`MC_RTS];
assign	dtr_o = mcr[`MC_DTR];


//
// FIFO INSTANCES
//

UART_TX_FIFO fifo_tx(clk, wb_rst_i, tf_data_in, tf_data_out,
	tf_push, tf_pop, tf_underrun, tf_overrun, tf_count);

UART_RX_FIFO fifo_rx(clk, wb_rst_i, rf_data_in, rf_data_out,
	rf_push, rf_pop, rf_underrun, rf_overrun, rf_count, rf_error_bit);
// Receiver FIFO parameters redefine
defparam fifo_rx.fifo_width = `FIFO_REC_WIDTH;

always @(posedge clk)   // synchrounous reading
//always @(wb_we_i or wb_addr_i or dlab or dl or rf_data_out or ier or iir or lcr or lsr or msr)
    if (~wb_we_i)   //if (we're not writing)
	case (wb_addr_i)
	`REG_RB : begin // Receiver FIFO or DL byte 1
			rf_pop <= #1 1;
			wb_dat_o <= #1 dlab ? dl[`DL1] : rf_data_out;
		  end

	`REG_IE	: wb_dat_o <= #1 dlab ? dl[`DL2] : ier;
	`REG_II	: wb_dat_o <= #1 iir;
	`REG_LC	: wb_dat_o <= #1 lcr;
	`REG_LS	: if (dlab)
			wb_dat_o <= #1 dl[`DL4];
		  else
		  begin
			wb_dat_o <= #1 lsr;
			// clear read bits
			lsr <= #1 lsr & 8'b00000001;
		  end
	`REG_MS	: wb_dat_o <= #1 msr;
	`REG_DL3: wb_dat_o <= #1 dlab ? dl[`DL3] : 8'b0;

	default:  wb_dat_o <= #1 8'b0; // ??
	endcase
    else
	wb_dat_o <= #1 8'b0;


//
//   WRITES AND RESETS   //
//
// Line Control Register
always @(posedge clk)
	if (wb_rst_i)
		lcr <= #1 8'b00000011; // 8n1 setting
	else
	if (wb_we_i && wb_addr_i==`REG_LC)
		lcr <= #1 wb_dat_i;

// Interrupt Enable Register or DL2
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		ier <= #1 4'b0000; // no interrupts after reset
	else
	if (wb_we_i && wb_addr_i==`REG_IE)
		if (dlab)
		begin
			dl[`DL2] <= #1 wb_dat_i;
			dlc <= #1 dl;  // reset the counter to dl value
		end
		else
			ier <= #1 wb_dat_i[3:0]; // ier uses only 4 lsb


// FIFO Control Register
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		fcr <= #1 4'b1100; // no interrupts after reset
	else
	if (wb_we_i && wb_addr_i==`REG_FC)
		fcr <= #1 {wb_dat_i[7:6],wb_dat_i[2:1]};

// Modem Control Register or DL3
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		mcr <= #1 5'b00000; // no interrupts after reset
	else
	if (wb_we_i && wb_addr_i==`REG_MC)
		if (dlab)
		begin
			dl[`DL3] <= #1 wb_dat_i;
			dlc <= #1 dl;
		end
		else
			mcr <= #1 wb_dat_i[4:0];

// TX_FIFO or DL1
always @(posedge clk or posedge wb_rst_i)
	if (!wb_rst_i && wb_we_i && wb_addr_i==`REG_TR)
		if (dlab)
		begin
			dl[`DL1] <= #1 wb_dat_i;
			dlc <= #1 dl;
		end
		else
			tf_push  <= #1 1;

// Receiver FIFO trigger level selection logic (asynchronous mux)
always @(fcr[`FC_TL])
	case (fcr[`FC_TL])
		2'b00 : trigger_level <= #1 1;
		2'b01 : trigger_level <= #1 4;
		2'b10 : trigger_level <= #1 8;
		2'b11 : trigger_level <= #1 14;
	endcase
	
// FIFO push and pop signals reset
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		tf_push <= #1 0;
	else
	if (tf_push == 1)
		tf_push <= #1 0;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		tf_pop <= #1 0;
	else
	if (tf_pop == 1)
		tf_pop <= #1 0;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		rf_push <= #1 0;
	else
	if (rf_push == 1)
		rf_push <= #1 0;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		rf_pop <= #1 0;
	else
	if (rf_pop == 1)
		rf_pop <= #1 0;


// DL4 write
always @(posedge clk)
	if (!wb_rst_i && wb_we_i && wb_addr_i==`REG_DL4)
	begin
		dl[`DL4] <= #1 wb_dat_i;
		dlc <= #1 dl;
	end

//
//  STATUS REGISTERS  //
//

// Modem Status Register
always @(posedge clk)
begin
	msr[`MS_DDCD:`MS_DCTS] <= #1 {dcd, ri, dsr, cts} ^ msr[`MS_DDCD:`MS_DCTS];
	msr[`MS_CDCD:`MS_CCTS] <= #1 {dcd, ri, dsr, cts};
end

// Divisor Latches reset
always @(posedge wb_rst_i)
	dl <= #1 32'b0;

// Line Status Register is after the transmitter

// Enable signal generation logic
always @(posedge clk)
begin
	if (|dl) // if dl<>0
		if (enable)
			dlc <= #1 dl;
		else
			dlc <= #1 dlc - 1;  // decrease count
end

always @(dlc)
	if (~|dlc)  // dlc==0 ?
		enable = 1;
	else
		enable = 0;

//
//	INTERRUPT LOGIC
//
reg	rls_int;  // receiver line status interrupt
reg	rda_int;  // receiver data available interrupt
reg	ti_int;   // timeout indicator interrupt
reg	thre_int; // transmitter holding register empty interrupt
reg	ms_int;   // modem status interrupt

reg	[5:0]	counter_t;	// counts the timeout condition clocks

always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
	begin
		rls_int  <= #1 0;
		rda_int  <= #1 0;
		ti_int   <= #1 0;
		thre_int <= #1 0;
		ms_int   <= #1 0;
	end
	else
	begin
		rls_int  <= #1 lsr[`LS_OE] | lsr[`LS_PE] | lsr['LS_FE] | lsr[`LS_BE];
		rda_int  <= #1 (rf_count >= trigger_level);
		thre_int <= #1 lsr[`LS_TFE];
		ms_int   <= #1 | msr[7:4]; // modem interrupt is pending when one of the modem inputs is asserted
		ti_int   <= #1 (counter_t == 0);
	end
end

always @(posedge clk or posedge wb_rst_i)
begin
	if (rls_int && ier[`IE_RLS])  // interrupt occured and is enabled  (not masked)
	begin
		iir[`II_II] <= #1 `II_RLS;	// set identification register to correct value
		iir				// and set the IIR bit 0 (interrupt pending)
	end
end



//
// TRANSMITTER LOGIC
//

`define S_IDLE        0
`define S_SEND_START  1
`define S_SEND_BYTE   2
`define S_SEND_PARITY 3
`define S_SEND_STOP   4
`define S_POP_BYTE    5

reg	[2:0]	state;
reg	[3:0]	counter16;
reg	[2:0]	bit_counter;   // counts the bits to be sent
reg	[6:0]	shift_out;	// output shift register
reg		bit_out;
reg		parity_xor;  // parity of the word

always @(posedge clk or posedge wb_rst_i)
begin
  if (wb_rst_i)
  begin
	state     <= #1 `S_IDLE;
	stx_o     <= #1 0;
	counter16 <= #1 0;
  end
  else
  if (enable)
  begin
	case (state)
	`S_IDLE	 :	if (~|tf_count) // if tf_count==0
			begin
				state <= #1 `S_IDLE;
				stx_o <= #1 0;
			end
			else
			begin
				tf_pop <= #1 1;
				stx_o  <= #1 0;
				state  <= #1 `S_POP_BYTE;
			end
	`S_POP_BYTE :	begin
				tf_pop <= #1 0;
				case (lcr[/*`LC_BITS*/1:0])  // number of bits in a word
				2'b00 : begin
					bit_counter <= #1 3'b100;
					parity_xor  <= #1 ^tf_data_out[4:0];
				     end
				2'b01 : begin
					bit_counter <= #1 3'b101;
					parity_xor  <= #1 ^tf_data_out[5:0];
				     end
				2'b10 : begin
					bit_counter <= #1 3'b110;
					parity_xor  <= #1 ^tf_data_out[6:0];
				     end
				2'b11 : begin
					bit_counter <= #1 3'b111;
					parity_xor <= #1 ^tf_data_out[7:0];
				     end
				endcase
				{shift_out[6:0], bit_out} <= #1 tf_data_out;
				state <= #1 `S_SEND_START;
			end
	`S_SEND_START :	begin
				if (~|counter16)
					counter16 <= #1 4'b1111;
				else
				if (counter16 == 1)
				begin
					counter16 <= #1 0;
					state <= #1 `S_SEND_BYTE;
				end
				else
					counter16 <= #1 counter16 - 1;
				stx_o <= #1 1;
			end
	`S_SEND_BYTE :	begin
				if (~|counter16)
					counter16 <= #1 4'b1111;
				else
				if (counter16 == 1)
				begin
					if (|bit_counter) // if bit_counter>0
					begin
						bit_counter <= #1 bit_counter - 1;
						{shift_out[5:0],bit_out  } <= #1 {shift_out[6:1], shift_out[0]};
						state <= #1 `S_SEND_BYTE;
					end
					else   // end of byte
					if (~lcr[`LC_PE])
					begin
						state <= #1 `S_SEND_STOP;
					end
					else
					begin
						case ({lcr[`LC_EP],lcr[`LC_SP]})
						2'b00:	bit_out <= #1 ~parity_xor;
						2'b01:	bit_out <= #1 1;
						2'b10:	bit_out <= #1 parity_xor;
						2'b11:	bit_out <= #1 0;
						endcase
						state <= #1 `S_SEND_PARITY;
					end
					counter16 <= #1 0;
				end
				else
					counter16 <= #1 counter16 - 1;
				stx_o <= #1 bit_out; // set output pin
			end
	`S_SEND_PARITY :	begin
				if (~|counter16)
					counter16 <= #1 4'b1111;
				else
				if (counter16 == 1)
				begin
					counter16 <= #1 0;
					state <= #1 `S_SEND_STOP;
				end
				else
					counter16 <= #1 counter16 - 1;
				stx_o <= #1 bit_out;
			end
	`S_SEND_STOP :  begin
				if (~|counter16)
					counter16 <= #1 4'b1111;
				else
				if (counter16 == 1)
				begin
					counter16 <= #1 0;
					state <= #1 `S_IDLE;
				end
				else
					counter16 <= #1 counter16 - 1;
				stx_o <= #1 0;
			end

		default : // should never get here
			state <= #1 `S_IDLE;
	endcase
  end // end if enable
end // transmitter logic


///
///  RECEIVER LOGIC
///

`define SR_IDLE		0
`define SR_REC_START	1
`define SR_REC_BIT	2
`define	SR_REC_PARITY	3
`define SR_REC_STOP	4
`define SR_CHECK_PARITY	5
`define SR_REC_PREPARE	6
`define SR_END_BIT	7
`define SR_CALC_PARITY	8
`define SR_WAIT1	9
`define SR_PUSH		10
`define SR_LAST		11

reg	[3:0]	rstate;
reg	[3:0]	rcounter16;
reg	[2:0]	rbit_counter;
reg	[7:0]	rshift;			// receiver shift register
reg		rparity;		// received parity
reg		rparity_error;
reg		rframing_error;		// framing error flag
reg		rbit_in;
reg		rparity_xor;

wire		rcounter16_eq_7 = (rcounter16 == 7);
wire		rcounter16_eq_0 = (rcounter16 == 0);
wire	[3:0]	rcounter16_minus_1 = rcounter16 - 1;

always @(posedge clk or posedge wb_rst_i)
begin
  if (wb_rst_i)
  begin
	rstate		<= #1 `SR_IDLE;
	rbit_in		<= #1 0;
	rcounter16	<= #1 0;
	rbit_counter	<= #1 0;
	rparity_xor	<= #1 0;
	rframing_error	<= #1 0;
	rparity_error	<= #1 0;
	rshift		<= #1 0;
  end
  else
  if (enable)
  begin
	case (rstate)
	`SR_IDLE :	if (srx_i==1)   // detected a pulse (start bit?)
			begin
				rstate <= #1 `SR_REC_START;
				rcounter16 <= #1 4'b1110;
			end
			else
				rstate <= #1 `SR_IDLE;
	`SR_REC_START :	begin
				if (rcounter16_eq_7)    // check the pulse
					if (srx_i==0)   // no start bit
						rstate <= #1 `SR_IDLE;
					else            // start bit detected
						rstate <= #1 `SR_REC_PREPARE;
				rcounter16 <= #1 rcounter16_minus_1;
			end
	`SR_REC_PREPARE:begin
				case (lcr[/*`LC_BITS*/1:0])  // number of bits in a word
				2'b00 : rbit_counter <= #1 3'b100;
				2'b01 : rbit_counter <= #1 3'b101;
				2'b10 : rbit_counter <= #1 3'b110;
				2'b11 : rbit_counter <= #1 3'b111;
				endcase
				if (rcounter16_eq_0)
				begin
					rstate		<= #1 `SR_REC_BIT;
					rcounter16	<= #1 4'b1110;
					rshift		<= #1 0;
				end
				else
					rstate <= #1 `SR_REC_PREPARE;
				rcounter16 <= #1 rcounter16_minus_1;
			end
	`SR_REC_BIT :	begin
				if (rcounter16_eq_0)
					rstate <= #1 `SR_END_BIT;
				if (rcounter16_eq_7) // read the bit
					case (lcr[/*`LC_BITS*/1:0])  // number of bits in a word
					2'b00 : rshift[4:0]  <= #1 {srx_i, rshift[4:1]};
					2'b01 : rshift[5:0]  <= #1 {srx_i, rshift[5:1]};
					2'b10 : rshift[6:0]  <= #1 {srx_i, rshift[6:1]};
					2'b11 : rshift[7:0]  <= #1 {srx_i, rshift[7:1]};
					endcase
				rcounter16 <= #1 rcounter16_minus_1;
			end
	`SR_END_BIT :   begin
				if (rbit_counter==0) // no more bits in word
					if (lcr[`LC_PE]) // choose state based on parity
						rstate <= #1 `SR_REC_PARITY;
					else
					begin
						rstate <= #1 `SR_REC_STOP;
						rparity_error <= #1 0;  // no parity - no error :)
					end
				else		// else we have more bits to read
				begin
					rstate <= #1 `SR_REC_BIT;
					rbit_counter <= #1 rbit_counter - 1;
				end
				rcounter16 <= #1 4'b1110;
			end
	`SR_REC_PARITY: begin
				if (rcounter16_eq_7)	// read the parity
				begin
					rparity <= #1 srx_i;
					rstate <= #1 `SR_CALC_PARITY;
				end
				rcounter16 <= #1 rcounter16_minus_1;
			end
	`SR_CALC_PARITY : begin    // rcounter equals 6
				rcounter16  <= #1 rcounter16_minus_1;
				rparity_xor <= #1 ^{rshift,rparity}; // calculate parity on all incoming data
				rstate      <= #1 `SR_CHECK_PARITY;
			  end
	`SR_CHECK_PARITY: begin	  // rcounter equals 5
				case ({lcr[`LC_EP],lcr[`LC_SP]})
				2'b00: rparity_error <= #1 ~rparity_xor;  // no error if parity 1
				2'b01: rparity_error <= #1 ~rparity;      // parity should sticked to 1
				2'b10: rparity_error <= #1 rparity_xor;   // error if parity is odd
				2'b11: rparity_error <= #1 rparity;	  // parity should be sticked to 0
				endcase
				rcounter16 <= #1 rcounter16_minus_1;
				rstate <= #1 `SR_WAIT1;
			  end
	`SR_WAIT1 :	if (rcounter16_eq_0)
			begin
				rstate <= #1 `SR_REC_STOP;
				rcounter16 <= #1 4'b1110;
			end
			else
			begin
				rcounter16 <= #1 rcounter16_minus_1;
//				rstate <= #1 `SR_WAIT1;
			end
	`SR_REC_STOP :	begin
				if (rcounter16_eq_7)	// read the parity
				begin
					rframing_error <= #1 srx_i; // no framing error if input is 0 (stop bit)
					rf_data_in <= #1 {rshift, rparity_error, rframing_error};
					rstate <= #1 `SR_PUSH;
				end
				rcounter16 <= #1 rcounter16_minus_1;
			end
	`SR_PUSH :	begin
///////////////////////////////////////
				$display($time, ": received: %b", rf_data_in);
				rf_push    <= #1 1;
				rstate     <= #1 `SR_LAST;
			end
	`SR_LAST :	begin
				if (rcounter16_eq_0)
					rstate <= #1 `SR_IDLE;
				rcounter16 <= #1 rcounter16_minus_1;
				rf_push <= #1 0;
			end
	default : rstate <= #1 `SR_IDLE;
	endcase
  end  // if (enable)
end // always of receiver

//
// Break condition detection.
// Works in conjuction with the receiver state machine
reg	[3:0]	counter_b;	// counts the 0 signals

always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		counter_b <= #1 4'd11;
	else
	if (enable)  // only work on enable times
		if (srx_i)
		begin
			counter_b <= #1 4'd11; // maximum character time length - 1
			lsr[`LS_BI] <= #1 0;   // break off
		end
		else
		if (counter_b == 0)            // break reached
			lsr[`LS_BI] <= #1 1;   // break detected flag set
		else
			counter_b <= #1 counter_b - 1;  // decrement break counter
end // always of break condition detection

///
/// Timeout condition detection

always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		counter_t <= #1 6'd44;
	else
	if (enable)
		if(rf_push | rf_pop | rda_int) // counter is reset when RX FIFO is accessed or above trigger level
			counter_t <= #1 6'd44;
		else
		if (counter_t != 0)  // we don't want to underflow
			counter_t <= #1 counter_t - 1;		
end

// Line Status Register
always @(posedge clk or wb_rst_i)
begin
	if (wb_rst_i)
		lsr <= #1 8'b01100000;
	else
	begin
		lsr[0] <= #1 (rf_count!=0);  // data in receiver fifo available
		lsr[1] <= #1 rf_overrun;     // Receiver overrun error
		lsr[2] <= #1 rf_data_out[1]; // parity error bit
		//lsr[4] (break interrupt is done in break detection, after the receiver FSM)
		lsr[3] <= #1 rf_data_out[0]; // framing error bit
		lsr[5] <= #1 (tf_count==0);  // transmitter fifo is empty
		lsr[6] <= #1 (tf_count==0 && state == `S_IDLE); // transmitter empty
		lsr[7] <= #1 rf_error_bit;
	end
end

endmodule
