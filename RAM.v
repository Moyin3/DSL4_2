`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.02.2026 11:29:10
// Design Name: 
// Module Name: RAM
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


module RAM(
    input CLK,
    inout [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input BUS_WE
    );
    
    reg [7:0] mem [0:127];
    
    integer i;
    initial begin
        for (i = 0; i < 128; i = i + 1)
            mem[i] = 8'h0;
        
        // Numeric constants
        mem[8'h06] = 8'd0;
        mem[8'h07] = 8'd1;
        mem[8'h08] = 8'd8;
        mem[8'h09] = 8'd160;
        mem[8'h0A] = 8'd120;
        mem[8'h0E] = 8'd3;
        
        // Colour table
        mem[8'h70] = 8'hE0;
        mem[8'h71] = 8'h03;
        mem[8'h72] = 8'h1C;
        mem[8'h73] = 8'hE0;
        mem[8'h74] = 8'h03;
        mem[8'h75] = 8'h1C;
    end
    
    wire ram_select = (BUS_ADDR[7] == 1'b0);
    
    always @(posedge CLK) begin
        if (BUS_WE && ram_select)
            mem[BUS_ADDR[6:0]] <= BUS_DATA;
    end
    
    assign BUS_DATA = (!BUS_WE && ram_select) ? mem[BUS_ADDR[6:0]] : 8'hZZ;
endmodule
