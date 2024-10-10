//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2024 02:30:33 PM
// Design Name: 
// Module Name: timer testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: provide driver, monitor, scoreboard and checker for
//              fifo verification.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fifo_CPU_model #(
    parameter FIFO_ENTRIES = 1024,
    parameter DATA_WIDTH   = 16
) (
  input  logic                   rst_n_i,
  output logic                   wr_o,
  output logic                   rd_o,
  input  logic                   clk_rd_i,
  input  logic                   clk_wr_i,
  output logic                   daf_o,
  output logic                   oe_o,
  input  logic                   fifo_empty_i,
  input  logic                   fifo_full_i,
  input  logic                   half_full_i,
  input  logic                   af_ae_i,
  output logic [DATA_WIDTH-1:0]  data_in_o,
  input  logic [DATA_WIDTH-1:0]  data_out_i
);

  // Initial default value
  initial begin
    wr_o      = 0;
    rd_o      = 0;
    daf_o     = 0;
    oe_o      = 0;
    data_in_o = '0;
  end

  // Write data
  task write_data;
    input [DATA_WIDTH-1:0] data;
    input wr;
    output [$clog2(FIFO_ENTRIES)-1:0] index;
    begin
        wr_o = wr;
        data_in_o = data;
        @(posedge clk_wr_i);
        index = tb.dut.w_pointer;
        if (wr_o) $display("%0tns Start write data: %04h into FIFO entrie: %0d", $time, data, index);
        wr_o = 0;
    end
  endtask

  // Read data
  task read_data;
    output [DATA_WIDTH-1:0] data;
    input rd;
    input oe;
    output [$clog2(FIFO_ENTRIES)-1:0] index;
    begin
      oe_o = oe;
      rd_o = rd;
      @(posedge clk_rd_i);
      index = tb.dut.r_pointer;
      #1;
      data = data_out_i;
      if (rd_o) $display("%0tns Start read data: %04h at FIFO entrie: %0d", $time, data_out_i, index);
      rd_o = 0;
      oe_o = 0;
    end
  endtask

  // Check pass/fail
  task check_by_pass;
    input [1:0] err_flag;
    begin
        if (err_flag[1]) begin
            $display("\n");
            $display("\033[32m"); // Green color for PASS
            $display(" ----------------------------------------------------- ");
            $display(" ----------------------------------------------------- ");
            $display(" ------- ########     ###     ######   ######  ------- "); 
            $display(" ------- ##     ##   ## ##   ##    ## ##    ## ------- "); 
            $display(" ------- ##     ##  ##   ##  ##       ##       ------- "); 
            $display(" ------- ########  ##     ##  ######   ######  ------- "); 
            $display(" ------- ##        #########       ##       ## ------- "); 
            $display(" ------- ##        ##     ## ##    ## ##    ## ------- "); 
            $display(" ------- ##        ##     ##  ######   ######  ------- "); 
            $display(" ----------------------------------------------------- ");
            $display(" ----------------------------------------------------- ");
            $display("                         PASS!");
            $display("\033[0m"); // Reset color
            $display("\n");
        end else if (err_flag[0]) begin
            $display("\n");
            $display("\033[31m"); // Red color for FAIL
            $display(" ----------------------------------------------------- ");
            $display(" ----------------------------------------------------- ");
            $display(" --------- ########    ###    #### ##       ---------- "); 
            $display(" --------- ##         ## ##    ##  ##       ---------- "); 
            $display(" --------- ##        ##   ##   ##  ##       ---------- "); 
            $display(" --------- ######   ##     ##  ##  ##       ---------- "); 
            $display(" --------- ##       #########  ##  ##       ---------- "); 
            $display(" --------- ##       ##     ##  ##  ##       ---------- "); 
            $display(" --------- ##       ##     ## #### ######## ---------- "); 
            $display(" ----------------------------------------------------- ");
            $display(" ----------------------------------------------------- ");
            $display("                         FAIL!");
            $display("\033[0m"); // Reset color
            $display("\n");
        end
    end
  endtask

endmodule