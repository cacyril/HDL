module Top_level
    (
	 input clk,
	// input reset_n,
	 input uart_rx,
	 inout i2c_io_scl,
	 inout i2c_io_sda,
	 output uart_tx
	 //output [7:0] debug_led
	 );
	 
	 wire i2c_start;
	 wire i2c_stop;
	 wire i2c_rw;
	 wire o_sda;
	 wire o_scl;
	 wire i_sda;
	 wire i_scl;
	 wire uart_tx_busy;	 
	 wire rst_uart_data_rdy;
	 wire uart_data_ready;
	 wire uart_rx_busy;
	 wire uart_tx_start;
	 wire clk_400KHz;
	 wire clk_100KHz;
	 wire clk_10KHz;
	 wire [7:0] uart_rx_data;
	 wire [7:0] uart_tx_data;
	 wire [7:0] i_i2c_data;
	 wire [7:0] o_i2c_data;
	 wire [3:0] o_i2c_status;
     
	 wire [4:0] c_debug_float;
	 wire [2:0] i2c_m_debug_float;
	 
	
	reg [3:0] reset_count = 0;
	wire reset_n = &reset_count;
	
	always @(posedge clk)
    begin
	   if(!reset_n)
		   reset_count <= reset_count + 4'b1;
	end
	 
	 UART_RX uart_0(.clk(clk),
	                .reset_n(reset_n),
	                .RX_LINE(uart_rx),
					.rst_data_rdy(rst_uart_data_rdy),
					.BUSY(uart_rx_busy),
					.DATA(uart_rx_data),
					.DATA_READY(uart_data_ready)
					);
					
	UART_TX uart_1(.clk(clk),
	               .reset_n(reset_n),
	               .START(uart_tx_start),
				   .DATA(uart_tx_data),
				   .TX_LINE(uart_tx),
				   .BUSY(uart_tx_busy)
				   );
				   
	i2c_master i2c_0(.i2c_clk(clk_400KHz),
	                 .m_clk(clk),
	                 .reset_n(reset_n),
	                 .i_addr_cmd_data(i_i2c_data),
					 .i_start(i2c_start),
					 .i_rw_data(i2c_rw),
					 .i_stop(i2c_stop),
					 .i_sda(i_sda),
					 .i_scl(i_scl),
					 .o_sda(o_sda),
					 .o_scl(o_scl),
					 .o_data(o_i2c_data),
					 .o_status(o_i2c_status)
//					 .debug({i2c_m_debug_float,debug_led[4:0]})
					 );
	assign i2c_io_sda = (o_sda)? 1'bz : 1'b0;
    assign i2c_io_scl = (o_scl)? 1'bz : 1'b0;
	assign i_scl = i2c_io_scl;
	assign i_sda = i2c_io_sda;
					 
	controller contr_0(.clk(clk),
	                   .reset_n(reset_n),
					   .data_ready_uart(uart_data_ready),
					   .rx_busy_uart(uart_rx_busy),
					   .tx_busy_uart(uart_tx_busy),
					   .i_data_uart(uart_rx_data),
					   .i_data_i2c(o_i2c_data),
					   .i_i2c_status(o_i2c_status),
					   .rst_uart_ready(rst_uart_data_rdy),
					   .o_uart_tx_start(uart_tx_start),
					   .i2c_strobes({i2c_stop, i2c_rw, i2c_start}),
					   .o_data_uart(uart_tx_data),
					   .o_data_i2c(i_i2c_data)
					   //.debug({c_debug_float,debug_led[7:5]})
					   );
	freq_divider freq_d0(.clk(clk),
	                    .reset_n(reset_n),
						 .clk_10KHz(clk_10KHz),
						 .clk_100KHz(clk_100KHz),
						 .clk_400KHz(clk_400KHz)
						 );	 
	 
endmodule 