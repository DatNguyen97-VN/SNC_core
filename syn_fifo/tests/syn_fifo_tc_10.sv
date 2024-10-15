//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2024 08:50:44 AM
// Design Name: 
// Module Name: testcase for AF/AE and empty flag when write/read pointer are assigned values
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

module syn_fifo_tc_10;

    logic [1:0] err_flag;

    syn_fifo_testbench #(`FIFO_ENTRIES, `DATA_WIDTH) tb ();

    initial begin
        // reset
        tb.cpu.reset();
        #1
        repeat (2) @(posedge tb.system.sys_wclk);
        // testcase of write/read pointer is max/4
        tb.cpu.title("Empty-Flag V1");
        // write
        $display("\n assigned value into both Pointers \n");
        tb.dut.w_pointer = `FIFO_ENTRIES/4;
        tb.dut.r_pointer = `FIFO_ENTRIES/4;
        #1
        // check data
        tb.cpu.check_Low(tb.dut.fifo_empty_o, err_flag);
        if (err_flag[0]) $finish;

        // testcase of write/read pointer is 3/4 max
        tb.cpu.title("Empty-Flag V2");
        // write
        $display("\n assigned value into both Pointers \n");
        tb.dut.w_pointer = 0.75*`FIFO_ENTRIES;
        tb.dut.r_pointer = 0.75*`FIFO_ENTRIES;
        #1
        // check data
        tb.cpu.check_Low(tb.dut.fifo_empty_o, err_flag);
        if (err_flag[0]) $finish;

        
        // testcase of write pointer is assigned
        tb.cpu.title("AF/AE-Flag V1");
        // write
        $display("\n FIFO contains X+1 Word \n");
        tb.dut.x_reg     = `X_VALUE;
        tb.dut.w_pointer = `X_VALUE + 1;
        tb.dut.r_pointer = 0;
        #1
        // check data
        tb.cpu.check_High(tb.dut.af_ae_o, err_flag);
        if (err_flag[0]) $finish;
        // write
        $display("\n FIFO contains X+2 Word \n");
        tb.dut.x_reg     = `X_VALUE;
        tb.dut.w_pointer = `X_VALUE + 2;
        tb.dut.r_pointer = 0;
        #1
        // check data
        tb.cpu.check_Low(tb.dut.af_ae_o, err_flag);
        if (err_flag[0]) $finish;
        // write
        $display("\n FIFO contains Max-X Word \n");
        tb.dut.x_reg     = `X_VALUE;
        tb.dut.w_pointer = `FIFO_ENTRIES-`X_VALUE;
        tb.dut.r_pointer = 0;
        #1
        // check data
        tb.cpu.check_Low(tb.dut.af_ae_o, err_flag);
        if (err_flag[0]) $finish;
        // write
        $display("\n FIFO contains Max-X+1 Word \n");
        tb.dut.x_reg     = `X_VALUE;
        tb.dut.w_pointer = `FIFO_ENTRIES-`X_VALUE+1;
        tb.dut.r_pointer = 0;
        #1
        // check data
        tb.cpu.check_High(tb.dut.af_ae_o, err_flag);
        if (err_flag[0]) $finish;

        
        // testcase of read pointer is assigned
        tb.cpu.title("AF/AE-Flag V2");
        // write
        $display("\n FIFO contains X+1 Word \n");
        tb.dut.x_reg     = `X_VALUE;
        tb.dut.w_pointer = `FIFO_ENTRIES;
        tb.dut.r_pointer = `FIFO_ENTRIES-`X_VALUE-1;
        #1
        // check data
        tb.cpu.check_High(tb.dut.af_ae_o, err_flag);
        if (err_flag[0]) $finish;
        // write
        $display("\n FIFO contains X+2 Word \n");
        tb.dut.x_reg     = `X_VALUE;
        tb.dut.w_pointer = `FIFO_ENTRIES;
        tb.dut.r_pointer = `FIFO_ENTRIES-`X_VALUE-2;
        #1
        // check data
        tb.cpu.check_Low(tb.dut.af_ae_o, err_flag);
        if (err_flag[0]) $finish;
        // write
        $display("\n FIFO contains Max-X Word \n");
        tb.dut.x_reg     = `X_VALUE;
        tb.dut.w_pointer = `FIFO_ENTRIES;
        tb.dut.r_pointer = `X_VALUE;
        #1
        // check data
        tb.cpu.check_Low(tb.dut.af_ae_o, err_flag);
        if (err_flag[0]) $finish;
        // write
        $display("\n FIFO contains Max-X+1 Word \n");
        tb.dut.x_reg     = `X_VALUE;
        tb.dut.w_pointer = `FIFO_ENTRIES;
        tb.dut.r_pointer = `X_VALUE-1;
        #1
        // check data
        tb.cpu.check_High(tb.dut.af_ae_o, err_flag);
        if (err_flag[0]) $finish;

        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule