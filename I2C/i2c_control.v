module i2c_control
    (input clk,
	 input reset_n,
	 input [2:0] control,
	 input [7:0] data_in,
	 output scl,
	 output sda,
	 output [3:0] status,
	 output [7:0] data_out
	 );
	 
	reg [7:0] s_data;
	reg [2:0] ctrl_in;
	wire in_reset;
	wire FREQ_400K;
	freq_divider freq_d0(.clk(clk),
	                     .reset(reset_n),
						 .clk_10KHz(),
						 .clk_100KHz(),
						 .clk_400KHz(FREQ_400K)
						 );
	
	i2c_master master_0(.i_clk(FREQ_400K),
	                    .i_addr_cmd_data(s_data),
						.i_start(ctrl_in[1]),
						.i_stop(ctrl_in[0]),
						.i_rw_data(ctrl_in[2]),
						.io_scl(scl),
						.io_sda(sda),
						.in_reset(in_reset),
						.o_data(data_out),
						.o_status(status)
						);
	always @(negedge clk)
	begin
	    if(in_reset)
		  ctrl_in <= 3'b0;
		else if(!in_reset && control)
		begin
		  s_data <= data_in;
		  ctrl_in <= control;
		end
	end
	
endmodule