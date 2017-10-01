module controller
   (input clk,
    input reset_n,
	input data_ready_uart,
	input rx_busy_uart,
	input tx_busy_uart,
	input [7:0] i_data_uart,
	input [7:0] i_data_i2c,
	input [3:0] i_i2c_status,
	output rst_uart_ready,
	output o_uart_tx_start,
	output reg [2:0] i2c_strobes,
	output [7:0] o_data_uart,
	output reg [7:0] o_data_i2c
	);
	
	parameter [2:0]
	    IDLE         = 0,
		DECODE       = 1,
		SEND_CMD     = 2,
		WAIT1        = 3,
		WAIT2        = 4,
		TX_RESPONSE1 = 5,
		TX_RESPONSE2 = 6
	;
	/* Decode parameters */
	parameter [3:0]
	    START         = 0,
	    S             = 1,
		P             = 2,
		R             = 3,
		W             = 4,
		SPACE         = 5,
		RETURN        = 6,
		P1            = 7,
		P2            = 8,    
		SIZE          = 9
	;
	
	
	/* Functions to check if data from UART is a valid hex_num number or alphabet character  */
	function is_Hex_Num(input [7:0] data);
		reg [9:0] temp;
		begin: check_hex_num
			integer i;
			for( i = 0; i < 10 ; i = i + 1)
			begin
			    temp[i] = (data == ("0" + i));
			end
		is_Hex_Num = temp[0] | temp[1] | temp[2] | temp[3] | temp[4] | temp[5] | temp[6] | temp[7] | temp[8] | temp[9];
		end
	endfunction
	function is_Hex_Alpha(input [7:0] data);
		reg [5:0] temp;
		begin: check_hex_alpha
			integer i;
			for( i = 0; i < 6 ; i = i + 1)
			begin
			    temp[i] =  (data == ("A" + i)) | (data == ("a" + i));
			end
		is_Hex_Alpha = temp[0] | temp[1] | temp[2] | temp[3] | temp[4] | temp[5];
		end
	endfunction
	/* Function converts valid Ascii characters (0 - 9, A - F) to equivalent Hex */
	function [3:0] convAscii2Hex(input [7:0] asciiChar );
	    convAscii2Hex = (asciiChar == "0") ? 4'h0 : (asciiChar == "1") ? 4'h1 : (asciiChar == "2") ? 4'h2 : (asciiChar == "3") ? 4'h3 : (asciiChar == "4") ? 4'h4:
			            (asciiChar == "5") ? 4'h5 : (asciiChar == "6") ? 4'h6 : (asciiChar == "7") ? 4'h7 : (asciiChar == "8") ? 4'h8 : (asciiChar == "9") ? 4'h9:
				        (asciiChar == "A") | (asciiChar == "a") ? 4'hA : (asciiChar == "B")| (asciiChar == "b")? 4'hB : (asciiChar == "C") | (asciiChar == "c")? 4'hC :
						(asciiChar == "D") | (asciiChar == "d")? 4'hD :  (asciiChar == "E") | (asciiChar == "e") ? 4'hE:  4'hF;
	endfunction
	/* Function converts hex number to equivalent Ascii character (0 - 9, A - F) */
	function [7:0] convHex2Ascii(input [3:0] hex_num);
	    convHex2Ascii = (hex_num == 4'h0) ? "0" : (hex_num == 4'h1) ? "1" : (hex_num == 4'h2) ? "2" : (hex_num == 4'h3) ? "3":
		                (hex_num == 4'h4) ? "4" : (hex_num == 4'h5) ? "5" : (hex_num == 4'h6) ? "6" : (hex_num == 4'h7) ? "7":
					    (hex_num == 4'h8) ? "8" : (hex_num == 4'h9) ? "9" : (hex_num == 4'hA) ? "A" : (hex_num == 4'hB) ? "B":
					    (hex_num == 4'hC) ? "C" : (hex_num == 4'hD) ? "D" : (hex_num == 4'hE) ? "E" : "F";
	endfunction
	
	reg [2:0] state = IDLE;
	reg [SIZE - 1 :0] decode = 0;
    reg [2:0] s_rw_p = 3'b0; /* Start, R/W and stop strobes */
    reg [7:0] i2c_param = 8'b0; /* 8 bit vector to hold address or data to i2c*/
	reg [7:0] data2_uart1 = 8'h00;
	reg [7:0] data2_uart2 = 8'h00;
	
	/* Just for simulation purposes to track state transitions textually */
	reg [10*8-1:0] my_state_text_0;
	reg [7*8-1:0]  my_state_text_1;
	
	/* Connected to output logic to indicate a valid command before a SEND_CMD state
	   This is enforce a start command is sent first and to avoid a hang in the state machine logic*/
	wire valid_cmd;
	reg start_inserted;
	assign valid_cmd = start_inserted & (|s_rw_p);
	
	/* I2c status */
	wire i2c_status_busy;
	wire i2c_status_err1;
	wire i2c_status_err2;
	wire i2c_status_data_ready;
	
	assign i2c_status_busy = i_i2c_status[1];
	assign i2c_status_err1 = i_i2c_status[3];
	assign i2c_status_err2 = i_i2c_status[2];
	assign i2c_status_data_ready = i_i2c_status[0];
	

	always @(posedge clk, negedge reset_n)
	begin
	   if(reset_n == 0)
		begin
		    state                <= IDLE;
	        decode               <= 0;
	        s_rw_p               <= 0;
	        i2c_param            <= 0;
	        data2_uart1          <= 0;
	        i2c_strobes          <= 0;
	        o_data_i2c           <= 0;
			start_inserted       <= 0;
		end
		else
		begin
		    case(state)
		    	IDLE:
		    	begin
		    		if(rx_busy_uart) /* There is a new transmission in progress*/
		    		begin
		    			state <= DECODE;
		    			decode[START] <= 1'b1;
		    			s_rw_p <= 3'b0;
		    		end
		    		else
		    			state <= IDLE;
		    	end
		    	DECODE:
		    	begin
		    	  if(data_ready_uart)
		    	  begin
                    case(1)
                      decode[START]:
		    		  begin
		    		    decode[START] <= 1'b0;
		    		    if((i_data_uart == "S") | (i_data_uart == "s"))
		    			begin
		    				decode[S] <= 1'b1;
		    				s_rw_p[0] <= 1'b1;
							start_inserted <= 1'b1;
		    			end
		    			if((i_data_uart == "P") | (i_data_uart == "p"))
		    			begin
		    				decode[P] <= 1'b1;
		    				s_rw_p[2] <= 1'b1;
		    			end
		    			if((i_data_uart == "R") | (i_data_uart == "r"))
		    			begin
		    				decode[R] <= 1'b1;
		    				s_rw_p[1] <= 1'b1;
		    			end
		    			if((i_data_uart == "W") | (i_data_uart == "w"))
		    			begin
		    				decode[W] <= 1'b1;
		    				s_rw_p[1] <= 1'b1;
		    			end
		    		  end
		    		  
		    		  decode[S]:
		    		  begin
		    			  decode[S] <= 1'b0;
		    			  if(i_data_uart == " ")
		    				  decode[SPACE] <= 1'b1;					   
		    		  end
		    		  
		    		  decode[P]:
		    		  begin
		    			 decode[P] <= 1'b0;
                         if(i_data_uart == "\r")
                             decode[RETURN] <= 1'b1;						 
		    		  end
		    		  decode[R]:
		    		  begin
		    			 decode[R] <= 1'b0;
                         if(i_data_uart == "\r")
                             decode[RETURN] <= 1'b1;						 
		    		  end
		    		  decode[W]:
		    		  begin
		    			  decode[W] <= 1'b0;
		    			  if(i_data_uart == " ")
		    				  decode[SPACE] <= 1'b1;
		    		  end
		    		  decode[SPACE]:
		    		  begin
		    			  decode[SPACE] <= 1'b0;
		    			  if(is_Hex_Num(i_data_uart) | is_Hex_Alpha(i_data_uart))
		    			  begin
		    				  decode[P1] <= 1'b1;
		    				  i2c_param[7:4] <= convAscii2Hex (i_data_uart); 
		    			  end
		    		  end
		    		  decode[P1]:
		    		  begin
		    			  decode[P1] <= 1'b0;
		    			  if(is_Hex_Num(i_data_uart) | is_Hex_Alpha(i_data_uart))
		    			  begin
		    				  decode[P2] <= 1'b1;
		    				  i2c_param[3:0] <= convAscii2Hex(i_data_uart);
		    			  end
		    		  end
		    		  decode[P2]:
		    		  begin
		    			  decode[P2] <= 1'b0;
		    			  if(i_data_uart == "\r")
		    				  decode[RETURN] <= 1'b1;
		    		  end
		    		  
		    		  default:
		    		  begin
		    			  data2_uart1 <= "X";
		    			  data2_uart2 <= "!";
		    		  end
                    endcase					 
                  end	
				  else if((i_data_uart == "\r") & (decode == 0))/* TX_RESPONSE1 state if invalid command syntax is received */
                      state <= TX_RESPONSE1;
 						 
		    	  else if(decode[RETURN]) /* If RETRUN character has been decoded after valid command syntax */
		    	  begin
		    		  decode[RETURN] <= 1'b0;
					  if(valid_cmd) 
		    		      state <= SEND_CMD;
					  else                  /* If syntax is valid but not a valid command */
					  begin
						  state <= TX_RESPONSE1;
						  data2_uart1 <= "X";
		    			  data2_uart2 <= "!";
					  end
		    	  end 
                  else
                      state <= DECODE;	/* More characters to decode */			  
		    	end
		    	SEND_CMD:
		    	begin
				  if(s_rw_p[2]) /* Reset the started inserted reg to 0 once stop has been received and processed*/
					  start_inserted <= 1'b0;
				
		    	  if(!i2c_status_busy) /* if i2c is not busy with any tx */
		    	  begin
		    		  i2c_strobes <= s_rw_p; /* Assign input strobes*/
		    	      o_data_i2c <= i2c_param; /*place data on i2c controller to i2c_master bus*/
		    		  state <= WAIT1;
		    	  end
		    	  else
		    		  state <= SEND_CMD;
		    	end
		        WAIT1: /* Wait until i2c has started executing instruction */
		    	begin
		    	    if(i2c_status_busy)
		    			state <= WAIT2;
		    		else
		    			state <= WAIT1;
		    	end
		    	WAIT2:
		    	begin
		    	    i2c_strobes <= 3'b0; /* Reset i2c input strobes and wait for response*/
		    	    if(!i2c_status_busy) /* Wait until i2c reports not busy */
		    		begin
		    			if(i2c_status_err1 | i2c_status_err2)
		    			begin
		    				data2_uart1 <= "N";
		    				data2_uart2 <= "A";
							start_inserted <= 1'b0; // reset start inserted in case of an acknowledgement error
		    			end
		    			else if(i2c_status_data_ready & (s_rw_p[1] | s_rw_p[0]))
		    			begin
		    				data2_uart1 <= convHex2Ascii(i_data_i2c[7:4]);
		    			    data2_uart2 <= convHex2Ascii(i_data_i2c[3:0]);
		    			end
		    			else
		    			begin
		    				data2_uart1 <= "O";
		    				data2_uart2 <= "K";
		    			end
		    		    state <= TX_RESPONSE1;
		    		end
		    	    else
		    		    state <= WAIT2;
		    	end
		    	TX_RESPONSE1:
		    	begin
		    	    if(!tx_busy_uart)
		    		begin
		    			state <= TX_RESPONSE2; 
		    		end
		    		else
		    			state <= TX_RESPONSE1;
		    	end
		    	TX_RESPONSE2:
		    	begin
		    	    if(!tx_busy_uart)
		    		begin
		    			state <= IDLE;
		    		end
		    		else
		    		begin
		    			state <= TX_RESPONSE2;
		    		end
		    	end
		    endcase
		end
	end
	
	
	assign o_uart_tx_start = ((state == TX_RESPONSE1) | (state == TX_RESPONSE2)) & !tx_busy_uart;
	assign o_data_uart =( {8{(state == TX_RESPONSE1)}} & data2_uart1) | ({8{(state == TX_RESPONSE2)}} & data2_uart2);
	assign rst_uart_ready = (state == DECODE) & data_ready_uart;
	
	
	always @(state)
    begin
	    case(state)
		    IDLE:            my_state_text_0 = "    IDLE";
			DECODE:          my_state_text_0 = "  DECODE";
			SEND_CMD:        my_state_text_0 = "SEND_CMD";
            WAIT1:           my_state_text_0 = "   WAIT1";
            WAIT2:           my_state_text_0 = "   WAIT2";
            TX_RESPONSE1:    my_state_text_0 = "TX_RESP1";
            TX_RESPONSE2:    my_state_text_0 = "TX_RESP2";
        endcase			
    end
	always @(decode)
	begin
	    case(1)
		    decode[START]: my_state_text_1 = "  START";
			decode[S]:     my_state_text_1 = " CHAR_S";
			decode[P]:     my_state_text_1 = " CHAR_P";
			decode[R]:     my_state_text_1 = " CHAR_R";
			decode[W]:     my_state_text_1 = " CHAR_W";
			decode[SPACE]: my_state_text_1 = "  SPACE";
			decode[RETURN]:my_state_text_1 = " RETURN";
			decode[P1]:    my_state_text_1 = "PARAM_1";
			decode[P2]:    my_state_text_1 = "PARAM_2";
			default:       my_state_text_1 = "  DONE";
		endcase
	end
endmodule 
    