//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2024 09:48:48 PM
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

module syn_fifo_tc_07;

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

        // testcase of Output Latch is off
        tb.cpu.title("Latch OFF");
        // write
        $display("\n write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
            write_data[w_index] = data_in;
        end
        #1
        // read
        $display("\n read data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            tb.cpu.read_data(data_out, 1'b1, 1'b0, r_index);
            read_data[r_index] = data_out;
        end
        // check data out is in-dependence state
        if (read_data === 'z) begin
            err_flag[1] = 1;
            tb.cpu.print('z,'z,2'b10);
        end else begin
            err_flag[0] = 1;
            tb.cpu.print(read_data[0],'z,2'b01);
        end
        
        // testcase of Output Latch is on
        tb.cpu.title("Latch ON");
        // write
        $display("\n write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
            write_data[w_index] = data_in;
        end
        #1
        // read
        $display("\n read data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
            read_data[r_index] = data_out;
        end
        // check data out is in-dependence state
        if (read_data == write_data) begin
            err_flag[1] = 1;
        end else begin
            err_flag[0] = 1;
        end

        // testcase for Check multi-level synchronous of empty flag 
        tb.cpu.title("Mul-SYN Empty Flag");
        $display("\n write first data \n");
        data_in = $urandom_range(`FIFO_ENTRIES);
        tb.cpu.write_data(data_in, 1'b1, w_index);
        // wait delay of multilevel synchronous
        repeat (3) @(posedge tb.sys_rclk);
        #1
        tb.cpu.check_High(tb.dut.fifo_empty_o, err_flag);

        // testcase for Check multi-level synchronous of full flag 
        tb.cpu.title("Mul-SYN Full Flag");
        // write
        $display("\n write data \n");
        for (int i = 0; i < `FIFO_ENTRIES; i++) begin
            data_in = $urandom_range(`FIFO_ENTRIES);
            tb.cpu.write_data(data_in, 1'b1, w_index);
            write_data[w_index] = data_in;
        end
        //
        #1
        $display("\n read first data \n");
        tb.cpu.read_data(data_out, 1'b1, 1'b1, r_index);
        // wait delay of multilevel synchronous
        repeat (2) @(posedge tb.sys_wclk);
        #1
        tb.cpu.check_High(tb.dut.fifo_full_o, err_flag);

        // check pass/fail
        tb.cpu.check_by_pass(err_flag);
        #10 $finish;
    end 

endmodule