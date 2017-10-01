module UART_RX
   (input clk,
    input reset_n,
	 input RX_LINE,
	 input rst_data_rdy,
	 output reg BUSY,
	 output reg [7:0] DATA = 8'b0,
	 output reg DATA_READY
	);
	 parameter BAUD_COUNT = 7'd104;
	 reg [3:0] INDEX = 4'h0;
	 reg [6:0] COUNTER = 7'b0;
	 reg RX_IN_PROGRESS = 1'b0;
	 reg [9:0] RX_DATA = 10'b0;
	 reg shift_rx_bit1 = 1'b1;
	 reg shift_rx_bit2 = 1'b1;
	 
	 
	 always @(posedge clk)
	 begin
	   if(reset_n == 0)
	   begin
		   shift_rx_bit1 <= 1'b1;
		   shift_rx_bit2 <= 1'b1;
		   RX_DATA <= 10'b0;
		   RX_IN_PROGRESS <= 1'b0;
		   INDEX <= 4'h0;
		   COUNTER <= 7'b0;
		   DATA_READY <= 1'b0;
	   end
	   else
	   begin
		 shift_rx_bit1 <= RX_LINE;
	     shift_rx_bit2 <= shift_rx_bit1;
			
		if(rst_data_rdy)
			DATA_READY <= 1'b0;
		
	     if(!RX_IN_PROGRESS & !shift_rx_bit2)
		    begin
		      RX_IN_PROGRESS <= 1'b1;
			  BUSY <= 1'b1;
			  COUNTER <= 0;
		    end
			
		  if(RX_IN_PROGRESS)
		    begin
			   if(COUNTER == BAUD_COUNT - 1)
			   begin
				   COUNTER <= 0;
				   if(INDEX == 10)
				   begin
					   if(!RX_DATA[0] & RX_DATA[9])
					   begin
						   DATA_READY <= 1'b1;
						   DATA <= RX_DATA[8:1];
					   end
					   INDEX <= 0;
					   RX_IN_PROGRESS <= 0;
					   BUSY <= 0;
				   end
			   end
			   else
					COUNTER <= COUNTER + 7'b1;
			 	 
			   if(COUNTER == (BAUD_COUNT >>1))
			   begin
			 	    if(INDEX < 4'd10)
			 		begin
			 		    RX_DATA[INDEX] <= shift_rx_bit2;
			 		    INDEX <= INDEX + 4'b1;
			 		end
			   end
           end
        end  
      end
endmodule 