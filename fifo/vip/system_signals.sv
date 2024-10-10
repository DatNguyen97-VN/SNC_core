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
    // Reset signal generation
    initial begin
        sys_rst = 1'b1;
        #157
        sys_rst = 1'b0;
        #140
        sys_rst = 1'b1;
    end

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
        #13;
        forever begin
            #10 sys_rclk = ~sys_rclk;
        end
    end

endmodule