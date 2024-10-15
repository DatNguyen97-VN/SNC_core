//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2024 10:05:15 AM
// Design Name: 
// Module Name: testcase for normal-reset and un-expected reset
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`define FIFO_ENTRIES 16
`define DATA_WIDTH   08
`define X_VALUE      05

module syn_fifo_tc_11;
    
    logic [`DATA_WIDTH-1:0] data_in, data_out;
    logic [$clog2(`FIFO_ENTRIES)-1:0] w_index, r_index;
    logic [1:0] err_flag;

    syn_fifo_testbench #(`FIFO_ENTRIES, `DATA_WIDTH) tb ();

    initial begin
        // reset
        tb.cpu.reset();
        #1
        repeat (2) @(posedge tb.system.sys_wclk);
        // testcase of normal reset
        tb.cpu.title("Normal Reset");
        // write
        $display("\n write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        // reset
        tb.cpu.reset();
        $display("\n Reset is triggered \n");
        #1
        repeat (2) @(posedge tb.system.sys_wclk);
        // write
        $display("\n write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        // check full flag
        #1
        $display("\n Check full-flag ");
        tb.cpu.check_Low(tb.dut.fifo_full_o, err_flag);
        if (err_flag[0]) $finish;

        // read
        $display("\n read data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
        end
        // check empty flag
        #1
        $display("\n Check empty-flag ");
        tb.cpu.check_Low(tb.dut.fifo_empty_o, err_flag);
        if (err_flag[0]) $finish;

        
        // testcase of un-expected reset
        tb.cpu.title("Un-expected Reset");
        // write
        $display("\n write data \n");
        for (int i = 0; i < `FIFO_ENTRIES/2; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        // reset
        tb.cpu.reset();
        $display("\n Reset is triggered \n");
        #1
        repeat (2) @(posedge tb.system.sys_wclk);
        // write
        $display("\n write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        // check full flag
        #1
        $display("\n Check full-flag ");
        tb.cpu.check_Low(tb.dut.fifo_full_o, err_flag);
        if (err_flag[0]) $finish;

        // read
        $display("\n read data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
        end
        // check empty flag
        #1
        $display("\n Check empty-flag ");
        tb.cpu.check_Low(tb.dut.fifo_empty_o, err_flag);
        if (err_flag[0]) $finish;

        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule