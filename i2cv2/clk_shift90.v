`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chibueze Cyril Akaluka
// 
// Create Date:    16:59:09 09/30/2017 
// Design Name:    90 degrees Clock Shifter
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
	function integer return_int(input integer num);
	   return_int =  num;
	endfunction
	
    parameter STD_CLK_FREQ = 12000000,
	          CLK_0_FREQ   = 400000,
		      SAMPLE_COUNT = return_int(STD_CLK_FREQ/(4 * CLK_0_FREQ)),
		      FRACTION_DENOMINATOR   = 2,
			  FRACTION_NUMERATOR     = 1'b1,
			  NUMERATOR_WIDTH        = 1,
			  DENOMINATOR_WIDTH      = 2,
			  COUNTER_WIDTH = 4
			  ;
	reg [COUNTER_WIDTH -1: 0] counter = 0;
	reg count_enable = 0; /* enabled at edges of i_clk0, disabled after SAMPLE_COUNT is reached */
	
	reg reg_iclk0 = 0;

	reg [DENOMINATOR_WIDTH -1:0] adj_counter;
	
	wire pos_edge = ~reg_iclk0 & i_clk0;
	wire neg_edge = reg_iclk0 & ~i_clk0;
	wire count_start = (pos_edge | neg_edge);
	generate
	if(FRACTION_DENOMINATOR == 0)
	begin
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
	    	
	            reg_iclk0 <= i_clk0;
	    	
	    	   if(count_start)
	    	      count_enable <= 1;
	    		
	            if(count_start | counter_enable)
	    	      if(counter == (SAMPLE_COUNT - 1) )
	    		  begin
	    		    o_clk90 <= ~i_clk0;
	    			counter <= 0;
	    			count_enable <= 1'b0;
	    		  end
	    		  else
	    		      counter <= counter + 1'b1;
            end			  
	    end
	end
	else if(FRACTION_DENOMINATOR != 0)
	begin
		always @(posedge std_clk, negedge reset_n)
	    begin
	        if(reset_n == 0)
		    begin
		        reg_iclk0 <= 0;
			    counter <= 0;
			    count_enable <= 0;
				adj_counter <= 0;
		    end
		    else
		    begin
		
	            reg_iclk0 <= i_clk0;
		
		        if(count_start)
		            count_enable <= 1;
			
	            if(count_start | count_enable)
		            if(counter == (SAMPLE_COUNT - 1'b1 + (({NUMERATOR_WIDTH{(adj_counter == FRACTION_DENOMINATOR-1)}}) & (FRACTION_NUMERATOR))))
			        begin
			          o_clk90 <= ~i_clk0;
				      counter <= 0;
				      count_enable <= 1'b0;
					  adj_counter <= adj_counter + 1'b1;
					  if(adj_counter == (FRACTION_DENOMINATOR -1))
						  adj_counter <= 0;
			        end
			        else
			            counter <= counter + 1'b1;
            end			  
	    end
	end
	endgenerate
	
endmodule
