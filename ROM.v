`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.02.2026 11:29:36
// Design Name: 
// Module Name: ROM
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


module ROM(
    input [7:0] ADDR,
    output [7:0] DATA
    );
    
    parameter RAMAddrWidth = 8;
    
    reg [7:0] rom_mem [2**RAMAddrWidth-1:0];
    
    initial
        $readmemh("Complete_Demo_ROM.txt", rom_mem);
        
    assign DATA = rom_mem[ADDR];
endmodule
