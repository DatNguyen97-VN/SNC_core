//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2024 11:13:48 AM
// Design Name: 
// Module Name: syn fifo testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: check function of Synchronous FIFO.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module syn_fifo_testbench #(
    parameter FIFO_ENTRIES = 1024,
    parameter DATA_WIDTH   = 16
);

    logic sys_rst;
    logic sys_rclk;
    logic sys_wclk;
    logic wr;
    logic rd;
    logic daf;
    logic oe;
    logic fifo_empty;
    logic fifo_full;
    logic half_full;
    logic af_ae;
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;

    // System clock
    system_signals system (
        .sys_rst  (sys_rst),
        .sys_rclk (sys_rclk),
        .sys_wclk (sys_wclk)
    );

    // Stimulus CPU
    fifo_CPU_model #(
        .FIFO_ENTRIES (FIFO_ENTRIES),
        .DATA_WIDTH   (DATA_WIDTH)
    ) cpu (
        .rst_n_i      (sys_rst),
        .wr_o         (wr),
        .rd_o         (rd),
        .clk_rd_i     (sys_rclk),
        .clk_wr_i     (sys_wclk),
        .daf_o        (daf),
        .oe_o         (oe),
        .fifo_empty_i (fifo_empty),
        .fifo_full_i  (fifo_full),
        .half_full_i  (half_full),
        .af_ae_i      (af_ae),
        .data_in_o    (data_in),
        .data_out_i   (data_out)
    );

    // Synchronus FIFO
    syn_fifo #(
        .FIFO_ENTRIES (FIFO_ENTRIES),
        .DATA_WIDTH   (DATA_WIDTH)
    ) dut (
        .rst_n_i      (sys_rst),
        .wr_i         (wr),
        .rd_i         (rd),
        .clk_rd_i     (sys_rclk),
        .clk_wr_i     (sys_wclk),
        .daf_i        (daf),
        .oe_i         (oe),
        .fifo_empty_o (fifo_empty),
        .fifo_full_o  (fifo_full),
        .half_full_o  (half_full),
        .af_ae_o      (af_ae),
        .data_in_i    (data_in),
        .data_out_o   (data_out)
    );
endmodule