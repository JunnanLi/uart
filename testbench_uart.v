/*
 *  uart_hardware -- Hardware for uart.
 *
 *  Please communicate with Junnan Li <lijunnan@nudt.edu.cn> when meeting any question.
 *  Copyright and related rights are licensed under the MIT license.
 *
 *  Data: 2021.11.20
 *  Description: testbench of uart. 
 */
`timescale 1 ns / 1 ps

module testbench();
	reg 	clk = 1;
	reg 	resetn = 0;
	
	wire 			uart_tx_o;
	reg 			uart_rx_i;
	reg 	[31:0]	addr_32b_i;
	reg 			wren_i,rden_i;
	reg 	[31:0]	din_32b_i;
	wire 	[31:0]	dout_32b_o;
	wire 			dout_32b_valid_o;
	wire 			interrupt_o;


	/** clk */
	always #5 clk = ~clk;
	/** reset */
	initial begin
		repeat (100) @(posedge clk);
		resetn <= 1;
	end
	

	uart uart_inst(
		.clk_50m_i(clk),
		.rst_n_i(resetn),
		.uart_tx_o(uart_tx_o),
		.uart_rx_i(uart_tx_o),
		.addr_32b_i(addr_32b_i),
		.wren_i(wren_i),
		.rden_i(rden_i),
		.din_32b_i(din_32b_i),
		.dout_32b_o(dout_32b_o),
		.dout_32b_valid_o(dout_32b_valid_o),
		.interrupt_o(interrupt_o)
	);

	reg [7:0] HelloWorld[12:0];
	reg [1023:0] firmware_file;
	initial begin
		if (!$value$plusargs("firmware=%s", firmware_file))
			firmware_file = "D:/1-code/vivado/uart_test_1120/uart-master/helloworld.txt";
		$readmemh(firmware_file, HelloWorld);
	end

	reg [31:0]	cnt_clk;
	reg [3:0]	cnt_char, cnt_wait_clk;
	always @(posedge clk or negedge resetn) begin
		if(!resetn) begin
			uart_rx_i		<= 1'b0;
			wren_i 			<= 1'b0;
			rden_i 			<= 1'b0;
			din_32b_i		<= 32'b0;
			addr_32b_i		<= 32'b0;
			cnt_clk 		<= 32'b0;
			cnt_char		<= 4'b0;
			cnt_wait_clk	<= 4'b0;
		end
		else begin
			cnt_clk 			<= 32'd1 + cnt_clk;
			if(cnt_clk == 32'd100) begin
				cnt_wait_clk	<= 4'b1 + cnt_wait_clk;
				if(cnt_wait_clk == 4'd0) begin
					cnt_char	<= 4'b1 + cnt_char;
					wren_i 		<= 1'b1;
					addr_32b_i	<= 32'h10010004;
					case(cnt_char)
						4'd0:		din_32b_i	<= {24'b0,HelloWorld[0]};
						4'd1:		din_32b_i	<= {24'b0,HelloWorld[1]};
						4'd2:		din_32b_i	<= {24'b0,HelloWorld[2]};
						4'd3:		din_32b_i	<= {24'b0,HelloWorld[3]};
						4'd4:		din_32b_i	<= {24'b0,HelloWorld[4]};
						4'd5:		din_32b_i	<= {24'b0,HelloWorld[5]};
						4'd6:		din_32b_i	<= {24'b0,HelloWorld[6]};
						4'd7:		din_32b_i	<= {24'b0,HelloWorld[7]};
						4'd8:		din_32b_i	<= {24'b0,HelloWorld[8]};
						4'd9:		din_32b_i	<= {24'b0,HelloWorld[9]};
						4'd10:		din_32b_i	<= {24'b0,HelloWorld[10]};
						4'd11:		din_32b_i	<= {24'b0,HelloWorld[11]};
						4'd12:		din_32b_i	<= {24'b0,HelloWorld[12]};
						default:	din_32b_i	<= 32'b0;
					endcase
				end
				else begin
					wren_i 		<= 1'b0;
				end
				if(cnt_char==4'd13) begin
					cnt_clk 	<= 32'd1 + cnt_clk;
					cnt_wait_clk<= 4'b0;
				end
				else
					cnt_clk 	<= cnt_clk;
			end
			else begin
				addr_32b_i		<= 32'h10010000;
				cnt_wait_clk	<= 4'b1 + cnt_wait_clk;
				if(interrupt_o == 1'b1 && cnt_wait_clk == 4'b0) begin
					rden_i 		<= 1'b1;
				end
				else begin
					rden_i 		<= 1'b0;
				end
			end
			if(dout_32b_valid_o == 1'b1)
				$display("%c", dout_32b_o[7:0]);
		end
	end


endmodule


