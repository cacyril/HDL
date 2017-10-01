module freq_divider
   (input clk,
   input reset_n,
    output reg clk_10KHz = 0,
    output reg clk_100KHz = 0,
	output reg clk_400KHz = 0
	);

	parameter 
	    CLK_FREQUENCY = 12000000,
	    CLK_10K_COUNT = CLK_FREQUENCY/(2*10000),
		CLK_100K_COUNT = CLK_FREQUENCY/(2*100000),
		CLK_400K_COUNT = CLK_FREQUENCY/(2*400000)
		;
	reg [12:0] counter_10khz = 13'b0;
	reg [7:0]  counter_100khz = 8'b0;
	reg [6:0]  counter_400khz = 7'b0;
	always @(posedge clk /*or negedge reset*/)
	begin
	    if(reset_n == 0)
		begin
		    counter_10khz <= 13'b0;
			counter_100khz <= 8'b0;
			counter_400khz <= 7'b0;
			clk_10KHz <= 0;
			clk_100KHz <= 0;
			clk_400KHz <= 0;
		end
	    else
		begin
		    if(counter_10khz == CLK_10K_COUNT - 1)
			begin
			    counter_10khz <= 0;
				clk_10KHz <= ~clk_10KHz;
			end
			else
			    counter_10khz <= counter_10khz + 13'b1;
				
			if(counter_100khz == CLK_100K_COUNT - 1)
			begin
			    counter_100khz <= 0;
				clk_100KHz <= ~clk_100KHz;
			end
			else
			    counter_100khz <= counter_100khz + 8'b1;
				
			if(counter_400khz == CLK_400K_COUNT - 1)
			begin
			    counter_400khz <= 0;
				clk_400KHz <= ~clk_400KHz;
			end
			else
			    counter_400khz <= counter_400khz + 7'b1;
			
		end
	end
endmodule