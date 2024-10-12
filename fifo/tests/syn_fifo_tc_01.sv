//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 08:07:39 AM
// Design Name: 
// Module Name: testcase for register of AF/AE offset(X)
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

module syn_fifo_tc_01;

    logic [`DATA_WIDTH-1:0] X_value;
    logic [1:0] err_flag;
    logic [1:0] result;

    syn_fifo_testbench #(`FIFO_ENTRIES, `DATA_WIDTH) tb ();

    initial begin
        // testcase of User Mode
        tb.cpu.title("User Mode");
        // repeat testcase of X value from 1 to 7
        for (int i = 1; i <= 7; ++i) begin
            tb.system.sys_rst = 0;
            tb.cpu.daf_o      = 1;
            #50
            tb.cpu.data_in_o = i;
            // user mode of X value is triggered
            #50
            tb.cpu.daf_o     = 0;
            #50 
            // reset is triggered
            tb.system.sys_rst = 1;
            #50
            X_value = tb.dut.x_reg;
            // check pass/fail
            if (X_value == i) begin
                err_flag[1] = 1;
            end else begin
                err_flag[0] = 1;
            end
            tb.cpu.print(X_value, i, err_flag);
            // break if test is fail
            if (err_flag[0]) break;
        end
        // testcase of Default Mode
        tb.cpu.title("Default Mode");
        #100
        tb.system.sys_rst = 0;
        tb.cpu.daf_o      = 1;
        #100
        tb.system.sys_rst = 1;
        #10
        if (tb.dut.x_reg == 4) begin
            err_flag[1] = 1;
        end else begin
            err_flag[0] = 1;
        end
        tb.cpu.print(X_value, 4, err_flag);
        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule