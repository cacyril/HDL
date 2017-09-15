module I2C_Master_Top
   (input clk_50,
    input [9:0] SWITCH,
	input [3:0] KEY,
	output [9:0] LED,
	inout scl,
	inout sda
	);
	wire int_scl;
	wire int_sda;
	reg KEY_PRESSED = 1'b0;
	reg KEY_RELEASED = 1'b0;
	reg [2:0] control_in = 3'b0;
	reg [2:0] i_key;
	wire [3:0] dummy;
	assign LED[9:8] = dummy[3:2];
	i2c_control control_0(.clk(clk_50),
	            .reset_n(KEY[3]),
	            .control(control_in),
				.data_in(SWITCH[7:0]),
				.scl(int_scl),
				.sda(int_sda),
				.status(dummy),
				.data_out(LED[7:0])
				);
	
	
	
	always @(posedge clk_50)
	  begin			
	    control_in <= 3'b0;
		if(!(&KEY[2:0]))
		begin
		  KEY_PRESSED = 1'b1;
		  i_key <= ~KEY[2:0];
		end
		  
		if((&KEY[2:0]) & KEY_PRESSED)
		  KEY_RELEASED = 1'b1;
		  
		if(KEY_PRESSED & KEY_RELEASED)
		  begin
		     i_key <= 3'b0;
		     control_in <= i_key;
			 KEY_PRESSED <= 1'b0;
			 KEY_RELEASED <= 1'b0;
		  end
	 end
	
	assign scl = (int_scl) ? 1'bz : 1'b0;
	assign sda = (int_sda) ? 1'bz : 1'b0;
endmodule