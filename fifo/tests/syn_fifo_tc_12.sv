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

module syn_fifo_tc_12;

    logic [`DATA_WIDTH-1:0] data_in, data_out;
    logic [$clog2(`FIFO_ENTRIES)-1:0] w_index, r_index;
    logic [`FIFO_ENTRIES-1:0][`DATA_WIDTH-1:0] write_data, read_data;
    logic [1:0] err_flag;

    syn_fifo_testbench #(`FIFO_ENTRIES, `DATA_WIDTH) tb ();

    initial begin
        // reset
        tb.cpu.reset();
        #1;
        repeat (2) @(posedge tb.sys_rclk);
        // testcase of simultaneously write/read data
        tb.cpu.title("Simultaneously Write/Read Data");
        // write
        $display("\n Write first-data \n");
        data_in = $urandom_range(`FIFO_ENTRIES);
        tb.cpu.write_data(data_in, 1'b1, w_index);
        write_data[w_index] = data_in;
        // wait 3 read clock
        repeat (3) @(posedge tb.sys_rclk);
        // simualtanneously write/read data
        $display("\n simualtanneously write/read data \n");
        #1;
        for (int i = 0; i < `FIFO_ENTRIES/2; i++) begin
            fork
                // write
                begin
                    data_in = $urandom_range(`FIFO_ENTRIES);
                    tb.cpu.write_data(data_in, 1'b1, w_index);
                    write_data[w_index] = data_in;
                end
                // read
                begin
                    tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
                    // check data
                    if (data_out == write_data[r_index]) begin
                        err_flag[1] = 1;
                    end else begin
                        err_flag[0] = 1;
                        tb.cpu.print(data_out, write_data[r_index], 2'b01);
                    end
                end
            join
        end

        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule