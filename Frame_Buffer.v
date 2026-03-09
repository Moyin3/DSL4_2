`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.01.2026 10:22:25
// Design Name: 
// Module Name: Frame_Buffer
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


// This modules is a dual-port 1-bit RAM


  module Frame_Buffer( 
///Port A - Read/Write
    input A_CLK, 
    input [14:0] A_ADDR,
    input A_DATA_IN,
    output reg A_DATA_OUT, 
    input A_WE,
    //Port B - Read Only 
    input B_CLK,
    input [14:0] B_ADDR,
    output reg B_DATA 
    );
    // A 256 x 128 1-bit memory to hold frame data
    //The LSBs of the address correspond to the X axis, and the MSBs to the Y axis
    
    reg memory [0:32767];
    
    
    always @(posedge A_CLK) begin
        if (A_WE) 
            memory[A_ADDR] <= A_DATA_IN;
        
        A_DATA_OUT <= memory[A_ADDR];
    end
    
    always @(posedge B_CLK) begin
        B_DATA <= memory[B_ADDR];
        
    end
    
    
endmodule
