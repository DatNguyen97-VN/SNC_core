//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/13/2024 08:13:14 AM
// Design Name: 
// Module Name: testcase for unexpected stop of write/read data
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

module syn_fifo_tc_09;

    logic [`DATA_WIDTH-1:0] data_in, data_out;
    logic [$clog2(`FIFO_ENTRIES)-1:0] w_index, r_index;
    logic [`FIFO_ENTRIES-1:0][`DATA_WIDTH-1:0] write_data, read_data;
    logic [1:0] err_flag;

    syn_fifo_testbench #(`FIFO_ENTRIES, `DATA_WIDTH) tb ();

    initial begin
        // reset
        tb.cpu.reset();
        #1
        repeat (2) @(posedge tb.system.sys_wclk);

        // testcase of un-expected stop write
        tb.cpu.title("Unexpected Stop Write");
        // 1st write
        $display("\n Write data \n");
        for (int i = 0; i < `FIFO_ENTRIES/2; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
            write_data[w_index] = data_in;
        end
        // 2nd write
        $display("\n Write data when WR is turn off \n");
        for (int i = 0; i < `FIFO_ENTRIES/2; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b0, w_index);
        end
        // 3rd write
        $display("\n Continue, write data \n");
        for (int i = 0; i < `FIFO_ENTRIES/2; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
            write_data[w_index] = data_in;
        end
        #1
        // check data
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            if (tb.dut.mem_array[i] == write_data[i]) begin
                err_flag[1] = 1;
            end else begin
                err_flag[0] = 1;
                tb.cpu.print(tb.dut.mem_array[i], write_data[i], 2'b01);
                $finish;
            end
        end

        // testcase of unexpected stop read
        tb.cpu.title("Unexpected Stop Read");
        // 1st read
        $display("\n Read data \n");
        for (int i = 0; i < `FIFO_ENTRIES/2; i++) begin
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
            read_data[r_index] = data_out;
        end
        // 2nd read
        $display("\n Read data when RD is turn off\n");
        for (int i = 0; i < `FIFO_ENTRIES/2; i++) begin
            tb.cpu.read_data(data_out, 1'b0, 1'b1, r_index);
        end
        // 3rd read 
        $display("\n Continue, Read data \n");
        for (int i = 0; i < `FIFO_ENTRIES/2; i++) begin
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
            read_data[r_index] = data_out;
        end
        #1
        // check data
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            if (read_data[i] == write_data[i]) begin
                err_flag[1] = 1;
            end else begin
                err_flag[0] = 1;
                tb.cpu.print(read_data[i], write_data[i], 2'b01);
                $finish;
            end
        end

        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule