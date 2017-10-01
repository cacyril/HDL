module UART_TX
   (input clk,
    input reset_n,
	 input START,
	 input [7:0] DATA,
	 output reg TX_LINE = 1'b1,
	 output reg BUSY = 1'b0
	);
	parameter BAUD_COUNT = 7'd104;
	
	reg TX_IN_PROGRESS = 1'b0;
	reg [6:0] COUNTER = 7'b0;
	reg [3:0] INDEX = 4'h0;
	reg [8:0] TX_DATA = 9'b0;
	always @(posedge clk)
	begin
	    if(reset_n == 0)
		begin
			TX_IN_PROGRESS <= 1'b0;
			COUNTER <= 7'b0;
			INDEX <= 4'b0;
			TX_DATA <= 9'b0;
			BUSY <= 1'b0;
			TX_LINE <= 1'b1;
		end
		else
		begin
	        if(!TX_IN_PROGRESS & START)
		    begin
			  TX_IN_PROGRESS <= 1'b1;
			  BUSY <= 1'b1;
			  TX_LINE <= 0; //Indicate start of transmission
			  TX_DATA[7:0] <= DATA[7:0];
			  TX_DATA[8] <= 1'b1;
			  INDEX <= 0;
			  COUNTER <= 0;
			end
		
		    if(TX_IN_PROGRESS)
		    begin
			  if(COUNTER == BAUD_COUNT -1)
			  begin
			    COUNTER <= 0;
				if(INDEX < 4'd9)
				begin
				  TX_LINE <= TX_DATA[INDEX];
				  INDEX <= INDEX + 4'b1;
				end
			    else
			    begin
			        INDEX <= 4'd0;
				    TX_IN_PROGRESS <= 1'b0;
				    BUSY <= 1'b0;
					TX_LINE <= 1'b1;
                end	
			  end
			  else
			    COUNTER <= COUNTER + 7'b1; 
			end
		end
	end
endmodule