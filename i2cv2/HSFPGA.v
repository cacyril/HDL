module HSFPGA
   (// FPGA connections
	 input CLOCK_50,
	// input  [9:0] SWITCH,
	// input  [3:0] KEY,
	 output [9:0] LED,
	 inout i2c_scl,
	 inout i2c_sda,
	 //HPS cONNECTIONS
	 inout HPS_UART_RX,
	 inout HPS_UART_TX,
	 output [14:0] HPS_DDR3_ADDR,
    output [2:0] HPS_DDR3_BA,
    output HPS_DDR3_CAS_N, 
    output HPS_DDR3_CKE,
    output HPS_DDR3_CK_N,
    output HPS_DDR3_CK_P,
    output HPS_DDR3_CS_N,
    output [3:0] HPS_DDR3_DM,
    inout [31:0] HPS_DDR3_DQ,
    inout [3:0] HPS_DDR3_DQS_N,
    inout [3:0] HPS_DDR3_DQS_P,
    output HPS_DDR3_ODT,
    output HPS_DDR3_RAS_N,
    output HPS_DDR3_RESET_N,
    input HPS_DDR3_RZQ,
    output HPS_DDR3_WE_N

	);
	
	wire [66:0] LOAN_IO_OE;
	wire [66:0] LOAN_IO_IN;
	wire [66:0] LOAN_IO_OUT;
	wire HPS_H2F_RST;
	i2c_uart u0 (
        .clk_clk                          (clk_12MHz),                          //               clk.clk
        .reset_reset_n                    (1'b1),                    //             reset.reset_n
		  .hps_0_h2f_reset_reset_n          (HPS_H2F_RST),
        .hps_0_h2f_loan_io_in             (LOAN_IO_IN),             // hps_0_h2f_loan_io.in
        .hps_0_h2f_loan_io_out            (LOAN_IO_OUT),            //                  .out
        .hps_0_h2f_loan_io_oe             (LOAN_IO_OE),             //                  .oe
        .hps_io_hps_io_gpio_inst_LOANIO49 (HPS_UART_RX), //            hps_io.hps_io_gpio_inst_LOANIO49
        .hps_io_hps_io_gpio_inst_LOANIO50 (HPS_UART_TX), //                  .hps_io_gpio_inst_LOANIO50
		  .memory_mem_a                     (HPS_DDR3_ADDR),                     //            memory.mem_a
        .memory_mem_ba                    (HPS_DDR3_BA),                    //                  .mem_ba
        .memory_mem_ck                    (HPS_DDR3_CK_P),                    //                  .mem_ck
        .memory_mem_ck_n                  (HPS_DDR3_CK_N),                  //                  .mem_ck_n
        .memory_mem_cke                   (HPS_DDR3_CKE),                   //                  .mem_cke
        .memory_mem_cs_n                  (HPS_DDR3_CS_N),                  //                  .mem_cs_n
        .memory_mem_ras_n                 (HPS_DDR3_RAS_N),                 //                  .mem_ras_n
        .memory_mem_cas_n                 (HPS_DDR3_CAS_N),                 //                  .mem_cas_n
        .memory_mem_we_n                  (HPS_DDR3_WE_N),                  //                  .mem_we_n
        .memory_mem_reset_n               (HPS_DDR3_RESET_N),               //                  .mem_reset_n
        .memory_mem_dq                    (HPS_DDR3_DQ),                    //                  .mem_dq
        .memory_mem_dqs                   (HPS_DDR3_DQS_P),                   //                  .mem_dqs
        .memory_mem_dqs_n                 (HPS_DDR3_DQS_N),                 //                  .mem_dqs_n
        .memory_mem_odt                   (HPS_DDR3_ODT),                   //                  .mem_odt
        .memory_mem_dm                    (HPS_DDR3_DM),                    //                  .mem_dm
        .memory_oct_rzqin                 (HPS_DDR3_RZQ)
    );
	 
	 Top_level u1(.clk(clk_12MHz),
	             .uart_tx(LOAN_IO_OUT[50]),
					 .uart_rx(LOAN_IO_IN[49]),
					 .i2c_io_scl(i2c_scl),
					 .i2c_io_sda(i2c_sda),
					 .debug_led(LED[7:0])
					);
					 
	pll_0002 pll_inst (
		.refclk   (CLOCK_50),   //  refclk.clk
		.rst      (1'b0),      //   reset.reset
		.outclk_0 (clk_12MHz), // outclk0.clk
		.locked   ()          // (terminated)
	);
					 
	
	assign LOAN_IO_OE[49] = 1'b0;
	assign LOAN_IO_OE[50] = 1'b1;
	
endmodule 