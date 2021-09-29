//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_device_if.v                                            ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/projects/uart16550/                ////
////                                                              ////
////  Documentation related to this project:                      ////
////  http://www.opencores.org/projects/uart16550/                ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  Device interface for testing purposes                       ////
////                                                              ////
////  Known problems (limits): When 1.5 stop bits are used, only  ////
////                           first stop bit is checked          ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing.                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - Igor Mohor (igorm@opencores.org)                      ////
////                                                              ////
////  Created and updated:   (See log for the revision history)   ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2001 Authors                                   ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
//
//
//
//



`include "uart_device_if_defines.v"

module uart_device_if (stx_i, rts_i, dtr_i, srx_o, cts_o, dsr_o, ri_o, dcd_o);

parameter DATA_WIDTH        = 36;
parameter clk_half_period   = 25; // clock

parameter FIFO_DEPTH        = 16;
parameter FIFO_ADR_WIDTH    = 4;


input                       stx_i;
input                       rts_i;
input                       dtr_i;
output                      srx_o;
output                      cts_o;
output                      dsr_o;
output                      ri_o;
output                      dcd_o;

reg   [159:0]               test_progress;            // Information about the test progress (20 characters in ASCII)
reg   [DATA_WIDTH-1:0]      packet, mem_data_out;
reg   [31:0]                adr;
reg                         read, write, clk;
reg                         tx_clk;                  // tx_clk = clk / (divider * 16).

reg                         rx_cnt_rst;
reg   [3:0]                 rx_cnt;
reg                         reset;
reg   [15:8]                rx_lcr;

reg   [FIFO_ADR_WIDTH-1:0]  fifo_read_adr, fifo_write_adr;
reg   [FIFO_ADR_WIDTH:0]    fifo_cnt;

reg   [23:0]                fifo [0:FIFO_DEPTH-1];
reg   [23:0]                data_from_fifo, data_for_fifo;
reg                         write_fifo, read_fifo;

reg   [31:0]                cnt;
reg                         cnt_enable;
reg                         receive_packet_end, receive_packet_end_q, sample;

reg   [15:0]                clock_divider;
reg   [3:0]                 rx_length;        // Data length

reg                         rx_sample_clock;
reg   [7:0]                 rx_data;            // After data
reg                         rx_parity;          // received parity
reg   [1:0]                 rx_stop;            // received stop bits
reg                         framing_error, parity_error;

reg                         tx_break_enable;  // This bit identifies the break bit (instead the one in the LCR)
reg   [15:0]                tx_break_delay;   // break is transmitted global_break_delay cycles after start
                                                  // (in 16 * clk units)
reg                         start_tx_break_cnt;
reg                         srx_break;
reg                         srx_serial;
reg   [31:0]                tx_break_cnt;
reg                         break_detected, break_detected_q;

reg   [23:0]                glitch_num;
reg                         enable_glitch;
reg                         glitch;

wire  [5:0]                 rx_break_detection_length;
wire  [DATA_WIDTH-1:0]      mem_data_in;
wire                        fifo_full, fifo_empty;

wire  [3:0]                 total_rx_length;  // Data length + 1 parity + 1 stop bits
wire                        rx_length5, rx_length6, rx_length7, rx_length8;   // data length = 5, 6,7 or 8 bits
wire                        rx_parity_enabled, rx_odd_parity, rx_even_parity, rx_stick1_parity;
wire                        rx_stick0_parity, rx_stop_bit_1, rx_stop_bit15, rx_stop_bit2;
wire rx_break;              // not used

integer                     delay, ii, kk, ll;
integer                     mcd;        // file handle

//assign srx_o = srx_serial & ~srx_break;
assign srx_o = (srx_serial ^ glitch) & ~srx_break;

assign cts_o  = 0;
assign dsr_o  = 0;
assign ri_o   = 0;
assign dcd_o  = 0;





// wire my_stx_i = srx_o;
wire my_stx_i = stx_i;


// Initializing variables at startup
initial
begin
  read                = 0;
  write               = 0;
  ii                  = 0;
  delay               = 5;
  srx_serial          = 1;
  srx_break           = 0;
  ll                  = 0;
  write_fifo          = 0;
  read_fifo           = 0;
  cnt_enable          = 0;
  receive_packet_end  = 0;
  tx_break_enable     = 0;
  tx_break_delay      = 0;
  start_tx_break_cnt  = 0;
  tx_break_cnt        = 0;
  break_detected      = 0;
  break_detected_q    = 0;
  glitch_num          = 0;
  enable_glitch       = 0;
  glitch               = 0;
  reset               = 0;
  #1 reset            = 1;
  #1 reset            = 0;
end


// Generating clock signal
always
begin
  clk = 1;
  forever #clk_half_period clk = ~clk;
end


// Generating divided clock signal that is used for data transmission.
always
begin
  tx_clk = 1;
  forever #delay tx_clk = ~tx_clk;
end


// Connecting memory with simulation data to the interface
uart_device_if_memory #(36) i_memory(.adr(adr), .data_in(mem_data_out), .data_out(mem_data_in), .read(read), .write(write));


//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//  Start: Main loop for communication (reading instructions from file)             //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////
initial
begin
  mcd = $fopen("uart_device_if.log");
  #1000;
  while(packet !== 36'h200000000)
  begin
    test_progress = "Read pckt from mem";
    read_packet(ii, packet);
    if(packet[35:24]==12'h0_00)                                                 // send packet
      begin
        $fdisplay(mcd,"(%0t) send_packet 0x%0x", $time, packet[23:0]);
        test_progress = "send_packet";
        send_packet(packet[23:0]);
      end
    else
    if(packet[35:24]==12'h0_01)                                                 // set dll
      begin
        $fdisplay(mcd,"(%0t) set_dll 0x%0x", $time, packet[15:0]);
        test_progress = "set_dll";
        set_dll(packet[15:0]);
      end
    else
    if(packet[35:24]==12'h0_02)                                                 // set rx lcr
      begin
        $fdisplay(mcd,"(%0t) set_rx_lcr 0x%0x", $time, packet[23:0]);
        test_progress = "set_rx_lcr";
        rx_lcr[15:8] = packet[15:8];
      end
    else
    if(packet[35:24]==12'h0_03)                                                 // glitch generation
      begin
        $fdisplay(mcd,"(%0t) generate_glitch 0x%0x", $time, packet[23:0]);
        test_progress = "generate_glitch";
        generate_glitch(packet[23:0]);
      end
    else
    if(packet[35:24]==12'h0_04)                                                 // set break
      begin
        if(packet[16])
          $fdisplay(mcd,"(%0t) set_break to activate after 0x%0x cycles (in 1/16th of cycle)", $time, packet[15:0]);
        else
          $fdisplay(mcd,"(%0t) disabling break", $time);
        test_progress = "set_break";
        set_break(packet[23:0]);
      end
    else
    if(packet[35:24]==12'h0_05)                                                 // check fifo empty
      begin
        $fdisplay(mcd,"(%0t) check_fifo_empty 0x%0x", $time, packet[23:0]);
        test_progress = "check_fifo_empty";
        check_fifo_empty(packet[23:0]);
      end
    else
    if(packet[35:24]==12'h0_06)                                               // Delay number of clk cycles
      begin
        $fdisplay(mcd,"\n(%0t) Delay 0x%0x clk cycles (do nothing in the meantime)", $time, packet[23:0]);
        test_progress = "Wait_clock_cycles";
        wait_clock_cycles(packet[23:0]);
      end
    else
    if(packet[35:24]==12'h1_00)                                               // read packet from fifo and compare
      begin
        $fwrite(mcd,"\n(%0t) read_fifo_&_compare", $time);
        test_progress = "read_fifo_&_compare";
        read_fifo_and_compare(packet[23:0]);
      end
    else
    if(packet == 36'h200000000)                                                 // end of simulation
      begin
        $fdisplay(mcd,"\n(%0t) Exit simulation (uart_device_if.v)", $time);
        test_progress = "Exit simulation";
      end
    else
      begin
        $fdisplay(mcd,"\n(%0t) ERROR: Unknown instruction in the vapi.log (%0d).", $time, ii);
        $stop;
      end

    ii=ii+1;
  end
  $fdisplay(mcd,"\n\n(%0t) END OF UART SIMULATION DETECTED", $time);
  #1000;
  $fclose(mcd);
  $stop;
end
//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//  End: Main loop for communication (reading instructions from file)               //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////




//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//  Start: Receiving data                                                           //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////
assign rx_length5 = ~rx_lcr[9] & ~rx_lcr[8]; // data length = 5 bits
assign rx_length6 = ~rx_lcr[9] &  rx_lcr[8]; // data length = 6 bits
assign rx_length7 =  rx_lcr[9] & ~rx_lcr[8]; // data length = 7 bits
assign rx_length8 =  rx_lcr[9] &  rx_lcr[8]; // data length = 8 bits

assign rx_parity_enabled =  rx_lcr[11];
assign rx_odd_parity     = ~rx_lcr[13] & ~rx_lcr[12] & rx_parity_enabled;
assign rx_even_parity    = ~rx_lcr[13] &  rx_lcr[12] & rx_parity_enabled;
assign rx_stick1_parity  =  rx_lcr[13] & ~rx_lcr[12] & rx_parity_enabled;
assign rx_stick0_parity  =  rx_lcr[13] &  rx_lcr[12] & rx_parity_enabled;

assign rx_break = rx_lcr[14];  // not used

assign rx_stop_bit_1 = ~rx_lcr[10];
assign rx_stop_bit15 =  rx_lcr[10] &  rx_length5;
assign rx_stop_bit2  =  rx_lcr[10] & ~rx_length5; // (length6 | length7 | length8);

always @ (rx_length5, rx_length6, rx_length7, rx_length8)
begin
  if(rx_length5)
    rx_length = 5;
  if(rx_length6)
    rx_length = 6;
  if(rx_length7)
    rx_length = 7;
  if(rx_length8)
    rx_length = 8;
end


// Total length of the received packet. Needed for proper generation of the receive_packet_end signal.
assign total_rx_length = rx_length + rx_parity_enabled + 1 + rx_stop_bit2; // data length + parity + 1 stop bit + second stop bit (when enabled)
assign rx_break_detection_length = total_rx_length + 1; // +1 is used because start bit was not included in total_rx_length.

// Generating cnt_enable signal.
always @ (posedge clk)
begin
  if(~cnt_enable)
    wait(~my_stx_i);
  cnt_enable = 1;
  receive_packet_end = 0;
  wait(receive_packet_end);
  cnt_enable = 0;
  wait(my_stx_i);   // Must be high to continue. This is needed because of the break condition
end


// Counter used in data reception
always @ (posedge clk)
begin
  if(cnt_enable)
    begin
      if(cnt==(8*clock_divider - 1) & my_stx_i)    // False start bit detection
        receive_packet_end = 1;
      if(cnt_enable)                                  // Checking is still enabled after rx_devider clocks
        cnt <=#1 cnt + 1;
      else
        cnt <=#1 0;
    end
  else
    cnt <=#1 0;
end


// Delayed receive_packet_end signal
always @ (posedge clk)
begin
  receive_packet_end_q = receive_packet_end;
end



// Generating sample clock and end of the frame (Received data is sampled with this clock)
always @ (posedge clk)
begin
  if(cnt==8*clock_divider-1)
    kk=0;
  else
  if(cnt==(8*clock_divider + 16*clock_divider*(kk+1) - 1))
    begin
      rx_sample_clock = 1;
      kk=kk+1;
      if(kk==total_rx_length)
        receive_packet_end = 1;
    end
  else
    rx_sample_clock = 0;
end



// Sampling data (received data). When finished, this data is written to fifo.
always @ (posedge clk)
begin
  if(rx_sample_clock)
    begin
      if(kk<=rx_length)                   // Sampling data
        begin
          ll<=0;                          // Stop bit index reset at the beginning of the data stage
          `ifdef SHOW_RECEIVED_BITS
          $fdisplay(mcd,"\t\t\t\t\t\t\t(kk=%0d) Reading data bits = %0x", kk, my_stx_i);
          `endif
          rx_data[kk-1] = my_stx_i;
        end
      else
        begin
          if(kk==(rx_length+1))
            begin
              if(rx_parity_enabled)
                begin
                  `ifdef SHOW_RECEIVED_BITS
                  $fdisplay(mcd,"\t\t\t\t\t\t\t(kk=%0d) Reading parity bits = %0x", kk, my_stx_i);
                  `endif
                end
              else
                begin
                  rx_stop[ll] = my_stx_i;
                  ll<=ll+1;
                end
              rx_parity = my_stx_i & rx_parity_enabled;
            end

          if(kk>=(rx_length+1+rx_parity_enabled))
            begin
              `ifdef SHOW_RECEIVED_BITS
              $fdisplay(mcd,"\t\t\t\t\t\t\t(kk=%0d) Reading stop bits = %0x", kk, my_stx_i);
              `endif
              rx_stop[ll] = my_stx_i;
              ll<=ll+1;
            end
        end
    end


  // Filling the rest of the data with 0
  if(rx_length == 5)
    rx_data[7:5] = 0;
  if(rx_length == 6)
    rx_data[7:6] = 0;
  if(rx_length == 7)
    rx_data[7] = 0;


  // Framing error generation
  framing_error = (rx_stop_bit_1 | rx_stop_bit15)? ~rx_stop[0] : ~(&rx_stop[1:0]);  // When 1 or 1.5 stop bits are used,
                                                                                    // only first stop bit is checked
  // Parity error generation
  if(rx_odd_parity)
    parity_error = ~(^{rx_data, rx_parity});
  else if(rx_even_parity)
    parity_error = ^{rx_data, rx_parity};
  else if(rx_stick0_parity)
    parity_error = rx_parity;
  else if(rx_stick1_parity)
    parity_error = ~rx_parity;
  else
    parity_error = 0;
end

//wire write_condition = my_stx_i | (break_detected & ~break_detected_q);
wire write_condition = my_stx_i | break_detected;
// Writing received data to FIFO
always @ (posedge clk)
begin
  if(receive_packet_end & ~receive_packet_end_q | break_detected & ~break_detected_q)
    wait(write_condition)   // Waiting for "end of cycle detected" or "break to be activated"
    begin

      `ifdef SHOW_RX_LCR
      if(rx_length5       )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_length5");
      if(rx_length6       )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_length6");
      if(rx_length7       )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_length7");
      if(rx_length8       )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_length8");
      if(rx_parity_enabled)
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_parity_enabled");
      if(rx_odd_parity    )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_odd_parity");
      if(rx_even_parity   )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_even_parity");
      if(rx_stick1_parity )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_stick1_parity");
      if(rx_stick0_parity )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_stick0_parity");
      if(rx_break         )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_break");
      if(rx_stop_bit_1    )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_stop_bit_1");
      if(rx_stop_bit15    )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_stop_bit15");
      if(rx_stop_bit2     )
        $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\trx_stop_bit2");
      `endif

      write_rx_data_to_fifo({6'h0, framing_error, parity_error, rx_lcr[15:8], rx_data});
    end
end


// Break detection
reg [31:0] rx_break_cnt;


always @ (posedge clk)
begin
  break_detected_q <= break_detected;
  if(my_stx_i)
    begin
      rx_break_cnt = 0;         // Reseting counter
      break_detected = 0;       // Clearing break detected signal
    end
  else
    rx_break_cnt = rx_break_cnt + 1;
  
  if(rx_break_cnt == rx_break_detection_length * 16 * clock_divider)
    begin
      $fdisplay(mcd, "\n(%0t) Break_detected.", $time);
      break_detected <= 1;
      test_progress = "Break_detected";
    end
end






//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//  End: Receiving data                                                             //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////





// Reading packet back from the memory
task read_packet;
  input   [31:0] address;
  output  [DATA_WIDTH-1:0] data;

  begin
    adr = address;
    #1;
    data = mem_data_in;
  end
endtask


// Seting DLL (clock divider)
task set_dll;
  input [15:0] divider;

  begin
    assign clock_divider = divider;                            // rx clock divider

    @ (posedge clk);
    #(2*clk_half_period) delay = (clock_divider*16*clk_half_period);    // tx clock divider
  end
endtask


// Sending packets
task send_packet;
  input [23:0] packet;

  reg [7:0] data;
  reg length5, length6, length7, length8;
  reg parity_enabled;
  reg odd_parity, even_parity, stick1_parity, stick0_parity;
  //  reg break;  // tx_break_enable is used
  reg stop_bit_1, stop_bit15, stop_bit2;
  reg parity_xor;

  integer length, jj;

  begin
    data[7:0] = packet[7:0];
    length5 = ~packet[9] & ~packet[8]; // data length = 5 bits
    length6 = ~packet[9] &  packet[8]; // data length = 6 bits
    length7 =  packet[9] & ~packet[8]; // data length = 7 bits
    length8 =  packet[9] &  packet[8]; // data length = 8 bits

    parity_enabled =  packet[11];
    odd_parity     = ~packet[13] & ~packet[12] & parity_enabled;
    even_parity    = ~packet[13] &  packet[12] & parity_enabled;
    stick1_parity  =  packet[13] & ~packet[12] & parity_enabled;
    stick0_parity  =  packet[13] &  packet[12] & parity_enabled;

    //    break = packet[14];  // tx_break_enable is used

    stop_bit_1 = ~packet[10];
    stop_bit15 =  packet[10] &  length5;
    stop_bit2  =  packet[10] & ~length5; // (length6 | length7 | length8);

    `ifdef SHOW_TX_LCR
    if(length5       )
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_length5");
    if(length6       )
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_length6");
    if(length7       )
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_length7");
    if(length8       )
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_length8");
    if(parity_enabled)
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_parity_enabled");
    if(odd_parity    )
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_odd_parity");
    if(even_parity   )
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_even_parity");
    if(stick1_parity )
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_stick1_parity");
    if(stick0_parity )
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_stick0_parity");
    if(tx_break_enable)
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_break");
    if(stop_bit_1    )
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_stop_bit_1");
    if(stop_bit15    )
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_stop_bit15");
    if(stop_bit2     )
      $fdisplay(mcd,"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\ttx_stop_bit2");
    `endif


    if(length5)
      begin
        length=5;
        parity_xor = ^data[4:0];
      end
    else if(length6)
      begin
        length=6;
        parity_xor = ^data[5:0];
      end
    else if(length7)
      begin
        length=7;
        parity_xor = ^data[6:0];
      end
    else if(length8)
      begin
        length=8;
        parity_xor = ^data[7:0];
      end

    // Sending start bit
    @ (posedge tx_clk);
    srx_serial = 0;
    if(glitch_num > 0)
      enable_glitch = 1;            // enabling glitch generation
    if(tx_break_enable)
      start_tx_break_cnt = 1;       // Start counter that counts break length
    @ (posedge tx_clk);

    // Sending data bits
    for(jj=0; jj<length; jj=jj+1)
      begin
        srx_serial = data[jj];
        @ (posedge tx_clk);
      end

    // Sending parity bit
    if(parity_enabled)
      begin
        if(odd_parity)
          srx_serial = ~parity_xor;
        else if(even_parity)
          srx_serial = parity_xor;
        else if(stick1_parity)
          srx_serial = 1;
        else if(stick0_parity)
          srx_serial = 0;
        @ (posedge tx_clk);
      end

    // Sending stop bits
    srx_serial = 1;
    @ (posedge tx_clk);  // 1 stop bit
    if(stop_bit15 | stop_bit2)
      @ (posedge tx_clk);  // Since only 1st stop bit is detected, there is no need to generate 1.5 stop bits.
                           // 2 stop bits are generated instead.
    enable_glitch = 0;
    test_progress = "end send packet";
  end
endtask



// Received data is written to fifo so it can be compared with the "expected" data later.
task write_rx_data_to_fifo;
  input [23:0] task_data_for_fifo;

  begin
    data_for_fifo = task_data_for_fifo;
    if(framing_error | parity_error)
      begin
        if(break_detected)
          begin
            data_for_fifo = 24'h004000;
//            data_for_fifo = (task_data_for_fifo & 24'hffff00) | 24'h004000;
            $fdisplay(mcd, "(%0t) Break packet written to fifo (0x%0x).", $time, data_for_fifo);
          end
        else
          begin
            $fdisplay(mcd,"(%0t) \t\tERROR: Framing error or parity error occured when receiving data (fe=%0x, pe=%0x)", $time,
                                framing_error, parity_error);
          end
      end
    `ifdef SHOW_FIFO_ACTIVITY
    else
      $fdisplay(mcd,"(%0t) Writing received packet to fifo: data=0x%0x, parity_error=%0x, framing_error=%0x, lcr=0x%0x",
                $time, data_for_fifo[7:0], data_for_fifo[16], data_for_fifo[17], data_for_fifo[15:8]);
    `endif

    @ (posedge clk);
    #1 write_fifo = 1;
    @ (posedge clk);
    #1 write_fifo = 0;

  end
endtask



// Read data form fifo (received packets were stored to fifo) and compare them with expected data
task read_fifo_and_compare;

  input [23:0] reference_packet;

  begin
    if(fifo_empty)
      $fdisplay(mcd,"\n(%0t) \t\tWARNING: Fifo still empty. Waiting for data reception.", $time);
    wait(~fifo_empty);
    @ (posedge clk);
    #1 read_fifo = 1;
    @ (posedge clk);    // data is read from fifo
    #1 read_fifo = 0;
    #1;                 // delay needed for data from fifo to propagate
    if(reference_packet != data_from_fifo)
      begin
        $fdisplay(mcd,"(%0t) \t\tERROR: Reference packet differs from received packet (reference_packet=%0x, data_from_fifo=%0x)", $time,
                  reference_packet, data_from_fifo);
        $stop;
      end
    else
      $fdisplay(mcd,"\t\t(%0t) Reference packet equals to received packet (reference_packet=%0x, data_from_fifo=%0x)", $time,
                  reference_packet, data_from_fifo);
    `ifdef SHOW_FIFO_ACTIVITY
    $fwrite(mcd," (data_from_fifo = 0x%0x, fifo_adr = 0x%0x)", data_from_fifo, fifo_read_adr-1); // -1 because pointer is already incremented
    `endif
  end
endtask


// Set break (or clear it)
task set_break;
  input [23:0] break_data;

  begin
    tx_break_enable = break_data[16];
    tx_break_delay  = break_data[15:0];
  end
endtask

task wait_clock_cycles;
  input [23:0] number_of_clocks;

  begin
    repeat(number_of_clocks)
      @ (posedge tx_clk);
  end
endtask


// Checking if receive fifo is full or empty
assign fifo_full    = fifo_cnt == FIFO_DEPTH;
assign fifo_empty   = fifo_cnt == 0;

// Writing and reading data to/from fifo
always @ (posedge clk or posedge reset)
begin
  if(reset)
    begin
      fifo_write_adr = 0;
      fifo_read_adr = 0;
      fifo_cnt = 0;
    end
  else
  begin
    case({read_fifo, write_fifo})
      2'b01:              // write
              begin
                if(fifo_full)
                  begin
                    $fdisplay(mcd,"(%0t) \t\tERROR: Fifo full.", $time);
                    $stop;
                  end
                fifo[fifo_write_adr] <=#1 data_for_fifo;
                fifo_write_adr <=#1 fifo_write_adr + 1;
                fifo_cnt <=#1 fifo_cnt + 1;
              end
      2'b10:              // read
              begin
                data_from_fifo <=#1 fifo[fifo_read_adr];
                fifo_read_adr <=#1 fifo_read_adr + 1;
                fifo_cnt <=#1 fifo_cnt - 1;
              end
      2'b11:              // read and write
              begin
                data_from_fifo <=#1 fifo[fifo_read_adr];
                fifo[fifo_write_adr] <=#1 data_for_fifo;
                fifo_read_adr <=#1 fifo_read_adr + 1;
                fifo_write_adr <=#1 fifo_write_adr + 1;
                fifo_cnt <=#1 fifo_cnt;
              end
      default:
              ;
    endcase
  end
end


// Checking if fifo is empty or full
task check_fifo_empty;
  input [23:0] fifo_empty_in;

  begin
    if(fifo_empty_in[0] !== fifo_empty)
      begin
        if(fifo_empty)
          $fdisplay(mcd,"(%0t) \t\tERROR: Fifo is empty but shouldn't be.", $time);
        else
          $fdisplay(mcd,"(%0t) \t\tERROR: Fifo is not empty but should be.", $time);
        $stop;
      end
  end

endtask


task generate_glitch;
  input [23:0] generate_glitch_data;

  begin
    glitch_num = generate_glitch_data;
  end
endtask


reg [31:0] glitch_cnt;
always @ (posedge clk or posedge enable_glitch)
begin
  if(enable_glitch)
    begin
      glitch_cnt <= glitch_cnt + 1;
      if(glitch_cnt == ((glitch_num-1) * clock_divider))
        glitch = 1;
      else
      if(glitch_cnt == (glitch_num * clock_divider))
        glitch = 0;
    end
  else
    glitch_cnt <= 0;
end


// Logic for setting/clearing break condition
always @ (posedge clk)
begin
  if(tx_break_enable && (tx_break_cnt == (tx_break_delay*clock_divider)))
    begin
      start_tx_break_cnt = 0;
      srx_break = 1;
    end
  else
  if(start_tx_break_cnt)    // Start counter that counts break length
    tx_break_cnt = tx_break_cnt + 1;
  else
    begin
      tx_break_cnt = 0;
      srx_break = 0;
    end
end





endmodule
