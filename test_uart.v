/*
 *  uart_hardware -- Hardware for uart.
 *
 *  Please communicate with Junnan Li <lijunnan@nudt.edu.cn> when meeting any question.
 *  Copyright and related rights are licensed under the MIT license.
 *
 *  Data: 2021.11.21
 *  Description: test for uart. 
 */
module test_uart(
  input           sys_clk,    //* system clock 50Mhz on board
  input           rst_n,      //* reset ,low active
  input           uart_rx,    //* fpga receive data
  output  wire    uart_tx     //* fpga send data
);
  //* interface for writing/reading uart's send/recv register;
  (* mark_debug = "true"*)reg   [31:0]  addr_32b_i;
  (* mark_debug = "true"*)reg           wren_i,rden_i;
  (* mark_debug = "true"*)reg   [31:0]  din_32b_i;
  (* mark_debug = "true"*)wire  [31:0]  dout_32b_o;
  (* mark_debug = "true"*)wire          dout_32b_valid_o;
  (* mark_debug = "true"*)wire          interrupt_o;

  uart uart_inst(
    .clk_50m_i(sys_clk),
    .rst_n_i(rst_n),
    .uart_tx_o(uart_tx),
    .uart_rx_i(uart_rx),
    .addr_32b_i(addr_32b_i),
    .wren_i(wren_i),
    .rden_i(rden_i),
    .din_32b_i(din_32b_i),
    .dout_32b_o(dout_32b_o),
    .dout_32b_valid_o(dout_32b_valid_o),
    .interrupt_o(interrupt_o)
  );

  //* fifo;
  reg         rden_data;
  wire  [7:0] dout_data;
  wire        empty_data;

  //* test program:
  //*   1) count number of strings in fifo (num_string), add one string when receiving a '\r',
  //*       sub one string after sending a '\r';
  (* mark_debug = "true"*)reg   [7:0] num_string; 
  (* mark_debug = "true"*)reg         add_1_str, sub_1_str;
  always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
      num_string    <= 8'b0;
      add_1_str     <= 1'b0;
      sub_1_str     <= 1'b0;
    end
    else begin
      if(dout_32b_valid_o == 1'b1 && dout_32b_o == 8'h0d) //* meet '\r'
        add_1_str   <= 1'b1;
      else
        add_1_str   <= 1'b0;
      if(wren_i == 1'b1 && din_32b_i[7:0] == 8'h0d) //* write '\r'
        sub_1_str   <= 1'b1;
      else
        sub_1_str   <= 1'b0;
      (*full_case, parallel_case*)
      case({add_1_str,sub_1_str})
        2'd0,2'd3:  num_string  <= num_string;
        2'd1:       num_string  <= num_string - 8'd1;
        2'd2:       num_string  <= num_string + 8'd1;
      endcase
    end
  end

  //*   2) output received data, and replace 'A' by 'B', add a '\n' after '\r';
  reg [3:0]   cnt_wait_clk;
  always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
      wren_i        <= 1'b0;
      rden_i        <= 1'b0;
      din_32b_i     <= 32'b0;
      addr_32b_i    <= 32'b0;
      cnt_wait_clk  <= 4'b0;
      rden_data     <= 1'b0;
    end
    else begin
      rden_data     <= 1'b0;
      rden_i        <= 1'b0;
      wren_i        <= 1'b0;
      cnt_wait_clk  <= 4'b1 + cnt_wait_clk;
      if(interrupt_o == 1'b1 && cnt_wait_clk == 4'b0) begin
        rden_i      <= 1'b1;
        addr_32b_i  <= 32'h10010000;
      end
      else if(num_string != 8'd0 && cnt_wait_clk == 4'b0) begin
        rden_data   <= 1'b1;
        wren_i      <= 1'b1;
        addr_32b_i  <= 32'h10010004;
        if(dout_data == 8'h41)
          din_32b_i <= {24'b0,8'h42};
        else
          din_32b_i <= {24'b0,dout_data};
      end
      else if(num_string == 8'd0 && cnt_wait_clk == 4'b0 && din_32b_i[7:0] == 8'h0d) begin
        wren_i      <= 1'b1;
        addr_32b_i  <= 32'h10010004;
        din_32b_i   <= {24'b0,8'h0a}; //* output '\n';
      end
    end
  end

  fifo_8b_512 data(
    .clk(sys_clk),
    .srst(!rst_n),
    .din(dout_32b_o[7:0]),
    .wr_en(dout_32b_valid_o),
    .rd_en(rden_data),
    .dout(dout_data),
    .full(),
    .empty(empty_data),
    .data_count()
  );


  //* output rx_data when receive "/n";

endmodule


