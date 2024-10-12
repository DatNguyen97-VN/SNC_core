//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 03:20:30 PM
// Design Name: 
// Module Name: testcase for write full data and half-full flag
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

module syn_fifo_tc_03;

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
        // testcase of write data V1
        tb.cpu.title("Write full Data V1");
        // write
        $display("\n 1st write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        #1;
        // read before second write
        $display("\n 1st read data before 2nd write \n");
        for (int i = 0; i < `FIFO_ENTRIES/2; i++) begin
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
        end

        for (int i = `FIFO_ENTRIES/2; i < `FIFO_ENTRIES; i++) begin
            write_data[i] = tb.dut.mem_array[i];
        end
        // second write
        $display("\n 2nd write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        #1;
        // check data after write full data
        for (int i = `FIFO_ENTRIES/2; i < `FIFO_ENTRIES; i++) begin
            if (tb.dut.mem_array[i] == write_data[i]) begin
                err_flag[1] = 1;
            end else begin
                err_flag[0] = 1;
                tb.cpu.print(write_data[i], tb.dut.mem_array[i], 2'b01);
                break;
            end
        end
        // reset
        tb.cpu.reset();
        #1;
        repeat (2) @(posedge tb.sys_wclk);
        // testcase of write data V2
        tb.cpu.title("Write full Data V2");
        // write
        $display("\n 1st write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
            write_data[w_index] = data_in;
        end
        #1;
        // write
        $display("\n 2st write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
        end
        #1;
        // check data after 2nd write
        $display("\n read data after 2nd write \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            // read
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
            //
            if (tb.dut.mem_array[r_index] == data_out) begin
                err_flag[1] = 1;
            end else begin
                err_flag[0] = 1;
                tb.cpu.print(write_data[r_index], data_out, 2'b01);
                break;
            end
        end
        #1;   
        // testcase of half-full flag
        tb.cpu.title("Half-full flag");
        // write
        $display("\n write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
            // check flag
            #1;
            if (w_index >= `FIFO_ENTRIES/2 - 1) begin
                if (tb.dut.half_full_o) begin
                    err_flag[1] = 1;
                end else begin
                    err_flag[0] = 1;
                    tb.cpu.print(tb.dut.half_full_o, 1'b1, 2'b01);
                    break;
                end
            end
        end
        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule