//`include "uart_rx.v"
//`include "uart_tx.v"

module uart_top
   (input clk_50,
	 input RX_LINE,
	 input [3:0] KEY,
	 input [9:0] SWITCH,
	 output TX_LINE,
	 output reg [9:0] LED
	);
	
	reg TX_START = 1'b0;
	reg [7:0] TX_DATA = 8'h00;
	reg KEY_PRESSED = 1'b0;
	reg KEY_RELEASED = 1'b0;
	wire TX_BUSY;
	wire RX_BUSY;
	wire [7:0] RX_DATA;
	wire ACK;
	UART_TX uart_tx_0  (.clk(clk_50),
	                  .START(TX_START),
							.DATA(TX_DATA),
							.TX_LINE(TX_LINE),
							.BUSY(TX_BUSY)
							);
	UART_RX uart_rx_0 (.clk(clk_50),
	                   .RX_LINE(RX_LINE),
							 .BUSY(RX_BUSY),
							 .DATA(RX_DATA),
							 .ACK(ACK)	
	                  );
	

	always @(posedge clk_50)
	  begin			
		if(!KEY[0])
		  KEY_PRESSED = 1'b1;
		  
		if(KEY[0] & KEY_PRESSED)
		  KEY_RELEASED = 1'b1;
		  
		if(KEY_PRESSED & KEY_RELEASED & !TX_BUSY)
		  begin
		    TX_START <= 1'b1;
			 TX_DATA   <= SWITCH[7:0];
			 KEY_PRESSED <= 1'b0;
			 KEY_RELEASED <= 1'b0;
		  end
		else
		  begin
		    TX_START <= 1'b0;
		  end
	 end
	always @(*)
	  begin
	    if(!RX_BUSY & ACK)
		   LED[7:0] = RX_DATA;
		else
		  LED = 8'h00;
	  end
endmodule	
	
	
