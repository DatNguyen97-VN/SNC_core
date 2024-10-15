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
        #1
        $display(" %07tns Start write data: %04h into FIFO entrie: %0d", $time, data, index);
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
      $display(" %07tns Start read  data: %04h at   FIFO entrie: %0d", $time, data_out_i, index);
      rd_o = 0;
      oe_o = 0;
    end
  endtask

  // Check signal's low state
  task check_Low;
    input signal;
    output [1:0] err_flag;
    begin
      if (!signal) begin
        err_flag[1] = 1;
        print(signal, 0, 2'b10);
      end else begin
        err_flag[0] = 1;
        print(signal, 0, 2'b01);
      end
    end
  endtask

  // Check signal's high state
  task check_High;
    input signal;
    output [1:0] err_flag;
    begin
      if (signal) begin
        err_flag[1] = 1;
        print(signal, 0, 2'b10);
      end else begin
        err_flag[0] = 1;
        print(signal, 1, 2'b01);
      end
    end
  endtask

  // Reset function
  task reset;
    tb.system.sys_rst = 1;
    #150
    tb.system.sys_rst = 0;
    #150
    tb.system.sys_rst = 1;
  endtask

  // Title print
  task title;
    input string in;
    begin
      $display("\n");
      $display(" ***************************************************** ");
      $display("             %20s                      ", in);
      $display(" ***************************************************** ");
      $display("\n");
    end
  endtask

  // Print information
  task print;
    input [DATA_WIDTH-1:0] data_in;
    input [DATA_WIDTH-1:0] data_ex;
    input [1:0]            flag;
    begin
      if (flag[0]) begin
        $display("\033[52m"); // purple color for FAIL
        $display(" ----------------------------------------------------- ");
        $display(" ----------------------------------------------------- ");
        $display(" ----- Data expected: %04h but actual Data: %04h ----- ", data_ex, data_in);
        $display(" ----------------------------------------------------- ");
        $display(" ----------------------------------------------------- ");
        $display("\033[0m"); // Reset color
      end else if (flag[1]) begin
        $display("\033[35m"); // purple color for PASS
        $display(" ----------------------------------------------------- ");
        $display(" ----------------------------------------------------- ");
        $display(" -------- Data expected and actual Data: %04h -------- ", data_in);
        $display(" ----------------------------------------------------- ");
        $display(" ----------------------------------------------------- ");
        $display("\033[0m"); // Reset color
      end
    end  
  endtask

  // Check pass/fail
  task check_by_pass;
    input [1:0] err_flag;
    begin
        if (err_flag[0]) begin
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
        end else if (err_flag[1]) begin
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
        end
    end
  endtask

endmodule