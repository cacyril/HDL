/*
 * An i2c master controller implementation. 7-bit address 8-bit data, r/w.
 *
 * Engineeer: Chibueze Cyril Akaluka
 * 
 */

`timescale 1ns / 1ps

module i2c_master(
    input m_clk,
    input i2c_clk,
	input reset_n,
    input [7:0] i_addr_cmd_data,		// Address and Data
	input i_start,
	input i_rw_data,
	input i_stop,
	input i_sda,
	input i_scl,
    output o_sda,
    output o_scl,
    output[7:0] o_data,
    output wire [3:0] o_status
    );

parameter [3:0]
          ST_IDLE         = 4'h1,
          ST_CMD_START    = 4'h2,
		  ST_CMD_STOP     = 4'h3,
		  ST_RD_DATA      = 4'h4,
		  ST_WR_ADDR_DATA = 4'h5,
		  ST_WAIT_NXT_CMD  = 4'h6,
		  ST_CHECK_ADDR_DATA_ACK = 4'h7,
		  ST_SEND_ACK     = 4'h8,
		  ST_SEND_NACK    = 4'h9
		  ;
/* For simulation purposes only. To track state transitions textually */		  
reg [8*10-1:0] my_state_text;


reg [7:0] addr_cmd_data = 8'b0;// Address with command reg, also serves as data register
reg cmd;
reg r_start;

reg status_err_nack_addr; 
reg status_err_nack_data;
reg status_data_ready;
reg status_tx_in_progress;
assign o_status = {status_err_nack_addr, status_err_nack_data, status_tx_in_progress, status_data_ready};

reg reg_sda;
reg reg_scl;
assign o_scl = reg_scl;
assign o_sda = reg_sda;

reg [3:0] state;
reg [3:0] clk0_state = ST_IDLE;
reg [3:0] clk0_count;// counter during clk0 positive edge;
reg [3:0] clk90_state = 4'b0;
reg [3:0] clk90_count; //counter during clk90 positive edge;

reg wr_scl_neg_clk0;
reg wr_scl_pos_clk0;

reg wr_sda_pos_clk90;
reg reg_sda_pos_clk90; 
reg wr_sda_neg_clk90;
reg reg_sda_neg_clk_90;

reg [7:0] in_data; /* Buffer for read command*/

wire clk0 = i2c_clk;
wire clk90;

clk_shift90 clk_s90(.std_clk(m_clk),
                    .reset_n(reset_n),
				    .i_clk0(i2c_clk),
				    .o_clk90(clk90)
				   );


always @(*)
begin
    case({clk0, clk90})
	    2'b11:
		    if(clk0_state != 0)
			    state <= clk0_state;
			else
			    state <= clk90_state;

		2'b01:
		    if(clk90_state != 0)
		        state <= clk90_state;
		    else
		        state <= clk0_state;
			
		default:                  /* For other cases, clk0 takes priority */
		    if(clk0_state != 0)
			    state <= clk0_state;
			else
			    state <= clk90_state;		
	endcase
	
	/* SDA line control 
	   The phase shifted clock controls writing data to slave*/
	if(wr_sda_neg_clk90 == 1'b1)
	    reg_sda = reg_sda_neg_clk_90;
	else if(wr_sda_pos_clk90 == 1'b1)
	    reg_sda = reg_sda_pos_clk90;
	else
	   reg_sda = 1'b1;
	
	/* SCL line control */
	case(state)
	    ST_WAIT_NXT_CMD:
		    if(wr_scl_neg_clk0 == 1'b1)
			    reg_scl = 1'b0;
            else
                reg_scl = 1'b1;			
		ST_IDLE:
		    reg_scl = 1'b1;
		ST_CMD_START:
		    reg_scl = 1'b1;
	    ST_CMD_STOP:
		    reg_scl = 1'b1;
		ST_SEND_ACK:
		   reg_scl  = 1'b0;
		ST_WR_ADDR_DATA:
		    if(wr_scl_pos_clk0)
			    reg_scl = 1'b0;
			else
			    reg_scl = clk0;
		default:
		    reg_scl = clk0;
	endcase
end

always @(posedge clk0, negedge reset_n)
begin
	if(reset_n == 0)
	begin
	    status_err_nack_data <= 0;
	    status_err_nack_addr <= 0;
	    status_data_ready <= 0;
	    status_tx_in_progress <= 0;
	    clk0_state <= ST_IDLE;
	    clk0_count <= 8;
	    r_start <= 0;
	    cmd <= 0;
		wr_scl_pos_clk0 <= 1'b0;
	    in_data <= 0;	
	end
	else
	begin
        clk0_state <= 0;
		wr_scl_pos_clk0 <= 1'b0;
	    case(state)
	        ST_IDLE:
	    	begin
	    	    if(i_start)
	    		begin
	    		    addr_cmd_data <= i_addr_cmd_data;
	    			clk0_state <= ST_CMD_START;
	    			r_start <= i_start; // Latch in control inputs for later use
	    			status_tx_in_progress <= 1'b1;
	    			status_err_nack_addr <= 1'b0;
	    			status_err_nack_data <= 1'b0;
	    			status_data_ready <= 1'b0;
	    		end
	    		else
	    		begin
	    		    clk0_state <= ST_IDLE;
	    			status_tx_in_progress <= 1'b0;
	    		end
	    	end
	        ST_CMD_START: 
	    	begin
				wr_scl_pos_clk0 <= 1'b1;
	    		cmd <= addr_cmd_data[0]; /*store the command bit for later use*/
	    		clk0_state <= ST_WR_ADDR_DATA;
	    	end
	    	
	        ST_CMD_STOP:
	    	begin
	    		clk0_state <= ST_IDLE;
	    	end
	    	ST_RD_DATA:
	    	begin
	    	    if(clk0_count > 0)
	    		begin
	    		    in_data[clk0_count - 1] <= i_sda;
	    			clk0_count <= clk0_count - 1'b1;
	    		end
	    		if(clk0_count == 1'b1)
	    		begin
	    		    clk0_state <= ST_WAIT_NXT_CMD;
	    			clk0_count <= 8;
					status_data_ready <= 1'b1;
	    		end
	    		else
	    		    clk0_state <= ST_RD_DATA;
	    	end
	    	ST_CHECK_ADDR_DATA_ACK:
	    	begin
	    	    if(i_sda != 0)
	    		begin
	    		  if(r_start) /* Address was written - usually accompanied by a start strobe */
	    			    status_err_nack_addr <= 1'b1;
	    		  else          /*else data was written*/
	    			  status_err_nack_data <= 1'b1;
	    			clk0_state <= ST_IDLE;  /*Error - go back to default state*/
	    		end
	    		else
	    		begin
	    		    if(r_start & cmd) /*if there was a start and command was to read: indicating first read sequence*/
					begin
					    r_start <= 0;
	    		        clk0_state <= ST_RD_DATA;
					end
	    		    else
	    		        clk0_state <= ST_WAIT_NXT_CMD; // Go to wait state for next command
	    		end
	    	end
	    	
	    	ST_SEND_ACK:
	    	/* Ack was sent at positive edge of clk90, and the slave is sampling it.
	    	 * There is new request for data. Go to the read state*/
	    	begin
	    	    clk0_state <= ST_RD_DATA;
	    	end
	    	
	    	ST_SEND_NACK:
	    	/* SDA line is already released during this phase
	    	 * There is a termination request. Go to stop state.*/
	    	 begin
	    	     clk0_state <= ST_CMD_STOP;
	    	 end
			ST_WAIT_NXT_CMD: /*Clock is disconnected after a half cycle when in this state and remains low */
	    	begin
	    		case({i_rw_data, i_start, i_stop})
	    		    3'b001:  /*i_stop signal*/
	    			begin
	    				status_tx_in_progress <= 1'b1;
						status_data_ready <= 1'b0;
	    			    if(cmd == 1'b1)
						begin
	    				    clk0_state <= ST_SEND_NACK;
						end
	    				else
						begin
	    				    clk0_state <= ST_CMD_STOP;
						end
	    		    end
	    			3'b010: /*i_start condition*/
	    			begin
	    			    addr_cmd_data <= i_addr_cmd_data;
	    				r_start <= i_start;
	    				clk0_state <= ST_CMD_START;
	    				status_tx_in_progress <= 1'b1;
						status_data_ready <= 1'b0;
	    			end
	    			3'b100: /*i_rw_data - Read data if cmd == 1 or Write data if cmd == 0*/
	    			begin
	    			    status_tx_in_progress <= 1'b1;
	    				addr_cmd_data <= i_addr_cmd_data;
	    			    if(cmd == 1'b1)
						begin
						    status_data_ready <= 1'b0;
	    				    clk0_state <= ST_SEND_ACK;
						end
	    				else
						begin
						    wr_scl_pos_clk0 <= 1'b1;
	    				    clk0_state <= ST_WR_ADDR_DATA;
						end
	    			end
					3'b000: /* No active strobe */
					begin
						status_tx_in_progress <= 1'b0;
	    				clk0_state <= state;
					end
	    			default: /* unresolveable strobe - stop communication and return to ST_IDLE */
	    			begin
	    			    status_tx_in_progress <= 1'b1;
	    			    if(cmd == 1'b1)
	    				    clk0_state <= ST_SEND_NACK;
	    				else
	    				    clk0_state <= ST_CMD_STOP;
	    			end
	    		endcase 
            end				
	    	
	    	
	    endcase
	end
end
always @(posedge clk90, negedge reset_n)
begin
	if(reset_n == 0)
	begin
		clk90_count <= 9;
		clk90_state <= 0;
		wr_sda_pos_clk90 <= 0;
		reg_sda_pos_clk90 <= 0;
	end
	else
	begin
        clk90_state <= 0;
	    wr_sda_pos_clk90 <= 0; /*Always relaease bus on next rising edge by default*/
	
	    case(state)
	        ST_WR_ADDR_DATA:
		    begin
		        if(clk90_count == 1'b1)
			    begin
			        clk90_count <= 9; /*Reset counter for future use*/
				    clk90_state <= ST_CHECK_ADDR_DATA_ACK;
				
			    end
			    else
			    begin
			        wr_sda_pos_clk90 <= 1'b1;
			     	reg_sda_pos_clk90 <= addr_cmd_data[clk90_count - 2];
				    clk90_count <= clk90_count - 1'b1;
				    clk90_state <= state;  // continue with the current state
			    end
		    end  
            ST_SEND_ACK: 
			begin
			    wr_sda_pos_clk90 <= 1'b1;
				reg_sda_pos_clk90 <= 1'b0;
			end	
            ST_CMD_STOP:
			begin
                wr_sda_pos_clk90 <= 1'b1;
			    reg_sda_pos_clk90 <= 1'b1;
            end	
            ST_SEND_NACK:
			begin
                wr_sda_pos_clk90 <= 1'b1;
			    reg_sda_pos_clk90 <= 1'b0;	
            end	
            ST_CMD_START:
            begin
                wr_sda_pos_clk90 <= 1'b1;
			    reg_sda_pos_clk90 <= 1'b0;
            end	
        endcase
    end		
end

/* To keep scl low after the first half cycle in ST_WAIT_NXT_CMD */
always @(negedge clk0, negedge reset_n)
begin
    if(reset_n == 0)
	    wr_scl_neg_clk0 <= 1'b0;
	else
	begin
	    wr_scl_neg_clk0 <= 1'b0;
        if(state == ST_WAIT_NXT_CMD)
	        wr_scl_neg_clk0  <= 1'b1;
	end
end

/* To assert the i2c stop condition */
always @(negedge clk90, negedge reset_n)
begin
    if(reset_n == 0)
    begin
	    wr_sda_neg_clk90 <= 0;
		reg_sda_neg_clk_90 <= 0;
	end
	else
	begin
	    wr_sda_neg_clk90 <= 1'b0;
		if(state == ST_CMD_STOP)
		begin
		    wr_sda_neg_clk90 <= 1'b1;
			reg_sda_neg_clk_90 <= 1'b1;
		end
		
	end
end

always @(state)
begin
  case(state)
          ST_IDLE:                 my_state_text = "      IDLE";
          ST_CMD_START:            my_state_text = "     START";
		  ST_CMD_STOP:             my_state_text = "      STOP";
		  ST_RD_DATA:              my_state_text = " READ_DATA";
		  ST_WR_ADDR_DATA:         my_state_text = "WR_AD_DATA";
		  ST_WAIT_NXT_CMD :        my_state_text = "  WAIT_CMD";
		  ST_CHECK_ADDR_DATA_ACK : my_state_text = " CHECK_ACK";
		  ST_SEND_ACK:             my_state_text = "  SEND_ACK";
		  ST_SEND_NACK:            my_state_text = " SEND_NACK";
  endcase
end


/* Data output assignment*/
assign o_data = {8{status_data_ready}} & in_data;
 
endmodule 