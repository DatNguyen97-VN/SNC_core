//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 08:52:33 PM
// Design Name: 
// Module Name: testcase for read Af/AE flag
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

module syn_fifo_tc_06;

    logic [`DATA_WIDTH-1:0] data_in, data_out;
    logic [$clog2(`FIFO_ENTRIES)-1:0] w_index, r_index;
    logic [`FIFO_ENTRIES-1:0][`DATA_WIDTH-1:0] write_data, read_data;
    logic [1:0] err_flag;

    syn_fifo_testbench #(`FIFO_ENTRIES, `DATA_WIDTH) tb ();

    initial begin
        // reset
        tb.system.sys_rst = 1;
        tb.cpu.daf_o = 1;
        #100
        tb.system.sys_rst = 0;
        tb.cpu.data_in_o = 7;
        #50
        // user mode of offset(x) is triggerd
        tb.cpu.daf_o = 0;
        #100
        tb.system.sys_rst = 1;
        // wait
        repeat (2) @(posedge tb.sys_wclk);

        // testcase of user mode for offset(x)
        tb.cpu.title("User Mode");
        // write
        $display("\n write data \n");
        for (int i = 1; i <= `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
            // check AF/AE Boundary
            #1
            if ((i >= tb.dut.x_reg + 2) && (i <= `FIFO_ENTRIES - tb.dut.x_reg)) begin // X+2 and FIFO_ENTRIES-X
                tb.cpu.title("Inside boundary X+2 and FIFO_ENTRIES-4");
                tb.cpu.check_Low(tb.dut.af_ae_o, err_flag);
                if (err_flag[0]) $finish;
            end else begin
                tb.cpu.title("Outside boundary X+2 and FIFO_ENTRIES-4");
                tb.cpu.check_High(tb.dut.af_ae_o, err_flag);
                if (err_flag[0]) $finish;
            end
        end
        #1;

        // testcase for default mode of offset(x)
        tb.cpu.title("Default Mode");
        // reset
        tb.system.sys_rst = 1;
        tb.cpu.daf_o = 1;
        #100
        tb.system.sys_rst = 0;
        #100
        // default mode of offset(x) is triggerd
        tb.system.sys_rst = 1;
        // wait
        repeat (2) @(posedge tb.sys_wclk);

        // write
        $display("\n write data \n");
        for (int i = 1; i <= `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
            // check AF/AE Boundary
            #1
            if ((i >= tb.dut.x_reg + 2) && (i <= `FIFO_ENTRIES - tb.dut.x_reg)) begin // X+2 and FIFO_ENTRIES-X
                tb.cpu.title("Inside boundary X+2 and FIFO_ENTRIES-4");
                tb.cpu.check_Low(tb.dut.af_ae_o, err_flag);
                if (err_flag[0]) $finish;
            end else begin
                tb.cpu.title("Outside boundary X+2 and FIFO_ENTRIES-4");
                tb.cpu.check_High(tb.dut.af_ae_o, err_flag);
                if (err_flag[0]) $finish;
            end
        end
        #1;
        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule