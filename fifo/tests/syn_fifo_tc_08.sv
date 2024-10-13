//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2024 07:46:28 AM
// Design Name: 
// Module Name: testcase for full flag when write/read pointer are assigned values
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

module syn_fifo_tc_08;

    logic [1:0] err_flag;

    syn_fifo_testbench #(`FIFO_ENTRIES, `DATA_WIDTH) tb ();

    initial begin
        // reset
        tb.cpu.reset();
        #1
        repeat (2) @(posedge tb.system.sys_wclk);
        // testcase of write pointer is max/2 and read pointer is 0
        tb.cpu.title("Full-Flag V1");
        // write
        $display("\n assigned value into Write Pointer \n");
        tb.dut.w_pointer = `FIFO_ENTRIES;
        #1
        tb.cpu.check_Low(tb.dut.fifo_full_o, err_flag);

        // testcase of write pointer is max and read pointer is max
        tb.cpu.title("Full-Flag V2");
        // write
        $display("\n assigned value into Write/Read Pointer\n");
        tb.dut.r_pointer = `FIFO_ENTRIES;
        tb.dut.w_pointer = 2*`FIFO_ENTRIES;
        #1
        tb.cpu.check_Low(tb.dut.fifo_full_o, err_flag);

        // testcase of write pointer is max/4 and read pointer is 0
        tb.cpu.title("Half-Full Flag V1");
        // write
        $display("\n assigned value into Write/Read Pointer\n");
        tb.dut.r_pointer = 0;
        tb.dut.w_pointer = `FIFO_ENTRIES/4;
        #1
        tb.cpu.check_Low(tb.dut.half_full_o, err_flag);

        // testcase of write pointer is max/2 and read pointer is max/4
        tb.cpu.title("Half-Full Flag V2");
        // write
        $display("\n assigned value into Write/Read Pointer\n");
        tb.dut.r_pointer = `FIFO_ENTRIES/4;
        tb.dut.w_pointer = `FIFO_ENTRIES/2;
        #1
        tb.cpu.check_Low(tb.dut.half_full_o, err_flag);

        // testcase of write pointer is 3/4 max and read pointer is max/2
        tb.cpu.title("Half-Full Flag V3");
        // write
        $display("\n assigned value into Write/Read Pointer\n");
        tb.dut.r_pointer = `FIFO_ENTRIES/2;
        tb.dut.w_pointer = 0.75*`FIFO_ENTRIES;
        #1
        tb.cpu.check_Low(tb.dut.half_full_o, err_flag);

        // testcase of write pointer is max and read pointer is 3/4 max
        tb.cpu.title("Half-Full Flag V4");
        // write
        $display("\n assigned value into Write/Read Pointer\n");
        tb.dut.r_pointer = 0.75*`FIFO_ENTRIES;
        tb.dut.w_pointer = `FIFO_ENTRIES;
        #1
        tb.cpu.check_Low(tb.dut.half_full_o, err_flag);

        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule