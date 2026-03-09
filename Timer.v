`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.02.2026 11:34:50
// Design Name: 
// Module Name: Timer
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


module Timer(
    input CLK,
    input RESET,

    inout [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input BUS_WE,

    output BUS_INTERRUPT_RAISE,
    input BUS_INTERRUPT_ACK
);

reg [31:0] counter;
reg interrupt;

assign BUS_DATA = 8'hZZ;

always @(posedge CLK) begin
    if (RESET) begin
        counter <= 0;
        interrupt <= 0;
    end else begin
        if (counter == 100_000_000) begin
            counter <= 0;
            interrupt <= 1;
        end else begin
            counter <= counter + 1;
        end

        if (BUS_INTERRUPT_ACK)
            interrupt <= 0;
    end
end

assign BUS_INTERRUPT_RAISE = interrupt;

endmodule
