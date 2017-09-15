/*
 * An i2c master controller implementation. 7-bit address 8-bit data, r/w.
 *
 * Copyright (c) 2015 Joel Fernandes <joel@linuxinternals.org>
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

`timescale 1ns / 1ps

module i2c_master(
    input i_clk,
	input reset_n,
    input [7:0] i_addr_cmd_data,		// Address and Data
	 input i_start,
	 input i_stop,
	 input i_rw_data,
    inout io_sda,
    output io_scl,
	output in_reset,
    output reg [7:0] o_data,		// Output data on reads
    output wire [3:0] o_status		// Request status
    );

parameter ST_IDLE         = 1,
          ST_CMD_START    = 2,
		  ST_CMD_STOP     = 3,
		  ST_RD_DATA      = 4,
		  ST_WR_ADDR_DATA = 5,
		  ST_WAIT_NXT_CMD  = 6,
		  ST_CHECK_ADDR_DATA_ACK = 7,
		  ST_WR_ADDR      = 8,
		  ST_SEND_ACK     =9,
		  ST_SEND_NACK    = 10;

reg [7:0] addr_cmd_data;// Address with command reg, also serves as data register
reg cmd;
reg r_rw_data, r_start;
wire [2:0] control_in;
assign control_in = {i_rw_data, i_start, i_stop};
//reg [6:0] addr;	// Address
//reg cmd;
//wire [7:0] addr_cmd;
//assign addr_cmd = {addr, cmd};

reg status_err_nack_addr, status_err_nack_data, status_data_ready, status_tx_in_progress;
assign o_status = {status_err_nack_addr, status_err_nack_data, status_tx_in_progress, status_data_ready};

assign io_sda = reg_sda;
reg reg_sda;

reg [3:0] state;
reg [3:0] pos_state;
reg [3:0] pos_count;// counter during positive cycle;
reg [3:0] neg_state;
reg [3:0] neg_count; //couner during negative cycle;

reg wr_sda_neg;
reg wr_sda_pos; /*Write enable for positive or negative edge of clock*/
reg reg_sda_pos;
reg reg_sda_neg; /*Data register for SDA for positive and negative clock cycles*/
reg [7:0] in_data;/*Data lactched from input for write or Buffer for read command*/

assign io_scl = (state == ST_WAIT_NXT_CMD)? 1'b1 : i_clk;

initial
begin 
    wr_sda_neg = 0;
	wr_sda_pos = 0;
	reg_sda_neg = 0;
	reg_sda_pos = 0;
	status_err_nack_addr = 0;
	status_err_nack_data = 0;
	status_data_ready = 0;
	status_tx_in_progress = 0;
	pos_state = ST_IDLE;
	neg_state = 0;
	pos_count = 8;
	neg_count = 9;
end



always @(*)
begin
    case(i_clk)
	    1:
		begin
		    if(pos_state != 0)
			    state <= pos_state;
			else
			    state <= neg_state;
				
			if(wr_sda_pos == 1'b1)
                reg_sda = reg_sda_pos;
            else if(wr_sda_neg == 1'b1)
                reg_sda = reg_sda_neg;
            else
                reg_sda = 1'b1;			
		end 
		0:
		begin
		    if(neg_state != 0)
			    state <= neg_state;
			else
			    state <= pos_state;
				
			if(wr_sda_neg == 1'b1)
			    reg_sda = reg_sda_neg;
			else if(wr_sda_pos == 1'b1)
			    reg_sda = reg_sda_pos;
			else
			    reg_sda = 1'b1;
		end
		
	endcase
end
always @(posedge i_clk )
begin
    pos_state <= 0;
	wr_sda_pos <= 0;
	case(state)
	    ST_IDLE:
		    if(i_start)
			begin
			    addr_cmd_data <= i_addr_cmd_data;
				pos_state <= ST_CMD_START;
				//r_rw_data <= i_rw_data;
				r_start <= i_start; // Latch in control inputs for later use
				status_tx_in_progress <= 1'b1;
			end
			else
			begin
			    pos_state <= ST_IDLE;
				status_tx_in_progress <= 1'b0;
			end
	    ST_CMD_START:
		begin
		    wr_sda_pos <= 1;
			reg_sda_pos <= 0;
			cmd <= addr_cmd_data[0]; /*store the command bit for later use*/
			pos_state <= ST_WR_ADDR_DATA;
		end
		
	    ST_CMD_STOP:
		begin
            wr_sda_pos <= 1'b1;
			reg_sda_pos <= 1'b1;
			pos_state <= ST_IDLE;
		end
		ST_RD_DATA:
		begin
		    if(pos_count > 0)
			begin
			    in_data[pos_count - 1] <= io_sda;
				pos_count <= pos_count - 1'b1;
			end
			if(pos_count == 1'b1)
			begin
			    pos_state <= ST_WAIT_NXT_CMD;
				pos_count <= 8;
			end
		end
		ST_CHECK_ADDR_DATA_ACK:
		begin
		    if(io_sda !=0)
			begin
			  if(r_start) /* Address was written - usually accompanied by a start strobe */
				    status_err_nack_addr <= 1'b1;
			  else          /*else data was written*/
				  status_err_nack_data <= 1'b1;
				pos_state <= ST_IDLE;  /*Error - go back to default state*/
			end
			else
			begin
			    if(r_start & cmd) /*if there was a start and command was to read: indicating first read sequence*/
			        pos_state <= ST_RD_DATA;
			    else
			        pos_state <= ST_WAIT_NXT_CMD; // Go to wait state for next command
			end
		end
		
		ST_SEND_ACK:
		/* Ack was sent last falling edge, and the slave is sampling it.
		 * There is new request for data. Go to the read state*/
		begin
		    pos_state <= ST_RD_DATA;
		end
		
		ST_SEND_NACK:
		/* SDA line is already release during this phase
		 * There is a termination request. Go to stop state.*/
		 begin
		     pos_state <= ST_CMD_STOP;
		 end
		
		ST_WAIT_NXT_CMD: /*Clock is disconnected when in this state, at resumption, clocking starts from high*/
		begin
		    status_tx_in_progress <= 1'b0;
			case(control_in)
			    3'b001:  /*i_stop signal*/
				begin
					status_tx_in_progress <= 1'b1;
				    if(cmd == 1'b1)
					    pos_state <= ST_SEND_NACK;
					else
					    pos_state <= ST_CMD_STOP;
			    end
				3'b010: /*i_start condition*/
				begin
				    addr_cmd_data <= i_addr_cmd_data;
					pos_state <= ST_CMD_START;
					status_tx_in_progress <= 1'b1;
				end
				3'b100: /*i_rw_data - Read data if cmd = 1 or Write data if cmd = 0*/
				begin
				    status_tx_in_progress <= 1'b1;
					addr_cmd_data <= i_addr_cmd_data;
					status_data_ready <= 1'b0;
				    if(cmd == 1'b1)
					    pos_state <= ST_SEND_ACK;
					else
					    pos_state <= ST_WR_ADDR_DATA;
				end
				3'b000:
				    pos_state <= state;
				default:
				begin
				    //status_err_invlaid_command <= 1'b1;
					pos_state <= state;
				end
			endcase 
			if(cmd)
			begin
			    status_data_ready <= 1'b1;
				o_data <= in_data;
			end
			else
			    status_data_ready <= 1'b0;
        end			
	endcase
end
always @(negedge i_clk)
begin
    neg_state <= 0;
	wr_sda_neg <= 0; /*Always relaease bus on next falling edge by default*/
	
	case(state)
	    ST_WR_ADDR_DATA:
		begin
		    if(neg_count == 1'b1)
			begin
			    neg_count <= 9; /*Reset counter for future use*/
				neg_state <= ST_CHECK_ADDR_DATA_ACK;
				
			end
			else
			begin
			    wr_sda_neg <= 1'b1;
				reg_sda_neg <= addr_cmd_data[neg_count -2];
				neg_count <= neg_count -1'b1;
				neg_state <= state;  // continue with the current state
			end
		end
	    			

    endcase
	
	if((state == ST_CMD_STOP) | (state == ST_SEND_ACK))
	begin
	    wr_sda_neg <= 1'b1;
		reg_sda_neg <= 1'b0;
	end		
end

assign in_reset = !(state == ST_IDLE) & !(state == ST_WAIT_NXT_CMD);
endmodule

