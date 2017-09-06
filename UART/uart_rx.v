module UART_RX
   (input clk,
	 input RX_LINE,
	 output reg BUSY,
	 output reg [7:0] DATA = 7'b0,
	 output reg ACK = 1'b0
	);
	 parameter BAUD_COUNT = 'd5207;
	 reg [3:0] INDEX = 4'h0;
	 reg [15:0] COUNTER;
	 reg RX_IN_PROGRESS = 1'b0;
	 reg [8:0] RX_DATA = 9'b0;
	 reg shift_rx_bit1 = 1'b1;
	 reg shift_rx_bit2 = 1'b1;
	 always @(posedge clk)
	   begin
		   shift_rx_bit1 <= RX_LINE;
			shift_rx_bit2 <= shift_rx_bit1;
		
	     if(!RX_IN_PROGRESS & !shift_rx_bit2)
		    begin
		      RX_IN_PROGRESS <= 1'b1;
			   BUSY <= 1'b1;
			   COUNTER <= 0;
		    end
			
		  if(RX_IN_PROGRESS)
		    begin
			   if(COUNTER < BAUD_COUNT)
			     COUNTER <= COUNTER + 16'b1;
			   else
			     COUNTER <= 0;
			 	 
			   if(COUNTER == ((BAUD_COUNT >>1) + 1))
			     begin
			 	    if(INDEX < 4'd9)
			 		   begin
			 		     RX_DATA[INDEX] <= shift_rx_bit2;
			 		     INDEX <= INDEX + 4'b1;
			 		   end
			 		 else
					   begin
					     if(!RX_DATA[0] & shift_rx_bit2)
					       begin
					         INDEX <= 0;
					   	   BUSY <= 0;
					   	   ACK <= 1'b1;
					   	   RX_IN_PROGRESS <= 0;
					   	 end
						  else
						    ACK <= 0;
					   end
				 end
         end
       if(!RX_IN_PROGRESS & ACK)
		   DATA <= RX_DATA[8:1];
		 else
		   DATA <= 8'b0;
      end
endmodule 