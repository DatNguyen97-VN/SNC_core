//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/08/2024 11:17:43 AM
// Design Name: 
// Module Name: generate system signal
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: check function: write and read data, status output.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module system_signals (
    output logic sys_rst,
    output logic sys_rclk,
    output logic sys_wclk
);
    // Write clock generation
    initial begin
        sys_wclk = 1'b0;
        #10;
        forever begin
            #10 sys_wclk = ~sys_wclk;
        end
    end

    // Read clock generation
    initial begin
        sys_rclk = 1'b0;
        #13; // modify to #10 when run tc_12 testcase
        forever begin
            #10 sys_rclk = ~sys_rclk;
        end
    end

endmodule