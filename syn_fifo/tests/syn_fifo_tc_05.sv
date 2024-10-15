//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 08:14:07 PM
// Design Name: 
// Module Name: testcase for read empty-fifo
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

module syn_fifo_tc_05;

    logic [`DATA_WIDTH-1:0] data_in, data_out;
    logic [$clog2(`FIFO_ENTRIES)-1:0] w_index, r_index;
    logic [`FIFO_ENTRIES-1:0][`DATA_WIDTH-1:0] write_data, read_data;
    logic [1:0] err_flag;

    syn_fifo_testbench #(`FIFO_ENTRIES, `DATA_WIDTH) tb ();

    initial begin
        // reset
        tb.cpu.reset();
        #1;
        repeat (3) @(posedge tb.sys_rclk);
        // testcase of read empty-data
        tb.cpu.title("Read Empty-Data");
        // read
        $display("\n read data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
            read_data[r_index] = data_out;
            // read pointer is always zero when empty fifo
            #1
            tb.cpu.check_Low(|r_index, err_flag);
            if (err_flag[0]) $finish;
        end
        #1;
        // check data
        if ((read_data === 'x)) begin
            err_flag[1] = 1;
        end else begin
            err_flag[0] = 1;
            tb.cpu.print(read_data, 'x, 2'b01);
            $finish;
        end
        // check empty-flag before write data
        $display(" \n Check check empty-flag before write data \n");
        tb.cpu.check_Low(tb.dut.fifo_empty_o, err_flag);
        if (err_flag[0]) $finish;

        // testcase of empty-flag after write full data
        tb.cpu.title("Empty-Flag after full data");
        // write
        $display("\n write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        #1;
        // read
        $display("\n read data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
            read_data[r_index] = data_out;
        end
        #1
        // check empty-flag after write data
        $display(" \n Check check empty-flag after write data \n");
        tb.cpu.check_Low(tb.dut.fifo_empty_o, err_flag);
        if (err_flag[0]) $finish;
        
        // testcase of empty-flag after write data
        tb.cpu.title("Empty-Flag after write data");
        // write
        $display("\n write data \n");
        for (int i = 0; i < `FIFO_ENTRIES/2; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        #1;
        // read
        $display("\n read data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
            read_data[r_index] = data_out;
        end
        #1
        // check empty-flag after write data
        $display(" \n Check check empty-flag after write data \n");
        tb.cpu.check_Low(tb.dut.fifo_empty_o, err_flag);
        if (err_flag[0]) $finish;

        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule