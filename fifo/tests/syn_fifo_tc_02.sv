//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 10:45:50 AM
// Design Name: 
// Module Name: testcase for write/read data
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

module syn_fifo_tc_02;

    logic [`DATA_WIDTH-1:0] data_in, data_out;
    logic [$clog2(`FIFO_ENTRIES)-1:0] w_index, r_index;
    logic [`FIFO_ENTRIES-1:0][`DATA_WIDTH-1:0] write_data, read_data;
    logic [1:0] err_flag;

    syn_fifo_testbench #(`FIFO_ENTRIES, `DATA_WIDTH) tb ();

    initial begin
        // reset
        tb.cpu.reset();
        #1;
        repeat (3) @(posedge tb.sys_wclk);
        // testcase of write data
        tb.cpu.title("Write Data");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
            write_data[w_index] = data_in;
        end
        #1;
        // check data
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            if (tb.dut.mem_array[i] == write_data[i]) begin
                err_flag[1] = 1;
            end else begin
                err_flag[0] = 1;
                tb.cpu.print(write_data[i], tb.dut.mem_array[i], 2'b01);
                break;
            end
        end
        #1;
        // testcase of read data
        tb.cpu.title("Read Data");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
            // check data
            if (write_data[i] == data_out) begin
                err_flag[1] = 1;
            end else begin
                err_flag[0] = 1;
                tb.cpu.print(data_out, write_data[i], 2'b01);
                break;
            end
        end
        // reset
        tb.cpu.reset();
        #1;
        repeat (3) @(posedge tb.sys_rclk);
        // testcase of swap write/read data
        tb.cpu.title("Swap Write/Read Data");
        for (int i = 0; i < 3*`FIFO_ENTRIES; i++) begin
            // write
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
            write_data[w_index] = data_in;
            #5;
            // read
            // wait 
            repeat (3) @(posedge tb.sys_rclk);
            #1;
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
            // check data
            if ((data_in == data_out) && (w_index == r_index)) begin
                err_flag[1] = 1;
            end else begin
                err_flag[0] = 1;
                tb.cpu.print(data_out, data_in, 2'b01);
                break;
            end
        end
        
        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule