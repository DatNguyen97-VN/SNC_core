//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 04:43:31 PM
// Design Name: 
// Module Name: testcase for full-flag
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

module syn_fifo_tc_04;

    logic [`DATA_WIDTH-1:0] data_in, data_out;
    logic [$clog2(`FIFO_ENTRIES)-1:0] w_index, r_index;
    logic [`FIFO_ENTRIES-1:0][`DATA_WIDTH-1:0] write_data, read_data;
    logic [1:0] err_flag;

    syn_fifo_testbench #(`FIFO_ENTRIES, `DATA_WIDTH) tb ();

    initial begin
        // reset
        tb.cpu.reset();
        #1;
        repeat (2) @(posedge tb.sys_wclk);
        // testcase of 1st Full-Flag
        tb.cpu.title("1st Full-Flag");
        // write
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        #1;
        //
        tb.cpu.check_Low(tb.dut.fifo_full_o, err_flag);
        if (err_flag[0]) $finish;
        #1;     
        // testcase of 2st Full-Flag
        tb.cpu.title("2st Full-Flag");
        // read
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
        end
        // write
        $display("\n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        #1;
        //
        tb.cpu.check_Low(tb.dut.fifo_full_o, err_flag);
        if (err_flag[0]) $finish;  

        // testcase of 3st Full-Flag
        tb.cpu.title("3st Full-Flag");
        // write
        $display("\n");
        $display(" 1st write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        #1;
        // read
        $display("\n");
        $display(" 1st read data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
        end
        //
        $display("\n");
        $display(" 2st write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        #1;
        // read
        $display("\n");
        $display(" 2st read data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
        end
        //
        $display("\n");
        $display(" 3st write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        #1;
        // check Full-Flag
        tb.cpu.check_Low(tb.dut.fifo_full_o, err_flag);
        if (err_flag[0]) $finish;

        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule