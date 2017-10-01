`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:59:09 09/30/2017 
// Design Name: 
// Module Name:    clk_shift90 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module clk_shift90
    (input std_clk, /* faster clock for sampling */
	 input reset_n,
	 input i_clk0,
	 output reg o_clk90 = 0       
    );
    parameter STD_CLK_FREQ = 12000000,
	          CLK_0_FREQ   = 100000,
		      SAMPLE_COUNT = STD_CLK_FREQ/(4 * CLK_0_FREQ),
		     // CORRECTION   = 0,
			  COUNTER_WIDTH = 5
			  ;
	reg [COUNTER_WIDTH -1: 0] counter = 0;
	reg count_enable = 0; /* enabled at edges of i_clk0, disabled after SAMPLE_COUNT is reached */
	
	reg [1:0] reg_iclk0 = 0;

	
	wire pos_edge = !reg_iclk0[1] & reg_iclk0[0];
	wire neg_edge = reg_iclk0[1] & !reg_iclk0[0];
	wire count_start = pos_edge | neg_edge;
	
    always @(posedge std_clk, negedge reset_n)
	begin
	    if(reset_n == 0)
		begin
		    reg_iclk0 <= 0;
			counter <= 0;
			count_enable <= 0;
		end
		else
		begin
		
	        reg_iclk0[0] <= i_clk0;
		    reg_iclk0[1] <= reg_iclk0[0];
		
		    if(count_start)
		      count_enable <= 1;
			
	        if(i_clk0 | !i_clk0)
		      if(counter == (SAMPLE_COUNT - 1))
			  begin
			    o_clk90 <= ~i_clk0;
				counter <= 0;
				count_enable <= 1'b0;
			  end
			  else
			if(count_enable)
			  counter <= counter + 1'b1;
        end			  
	end
	
endmodule
