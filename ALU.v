`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.02.2026 11:28:52
// Design Name: 
// Module Name: ALU
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


module ALU(
    input CLK,
    input RESET,
    input [7:0] IN_A,
    input [7:0] IN_B,
    input [3:0] ALU_Op_Code,
    output [7:0] OUT_RESULT
    );
    
    reg [7:0] Out;
    
    always @(posedge CLK) begin
        if (RESET)
            Out <= 8'h00;
        else begin
            case (ALU_Op_Code)
                4'h0: Out <= IN_A + IN_B;
                4'h1: Out <= IN_A - IN_B;
                4'h2: Out <= IN_A * IN_B;
                4'h3: Out <= IN_A << 1;
                4'h4: Out <= IN_A >> 1;
                4'h5: Out <= IN_A + 1'b1;
                4'h6: Out <= IN_B + 1'b1;
                4'h7: Out <= IN_A - 1'b1;
                4'h8: Out <= IN_B - 1'b1;
                4'h9: Out <= (IN_A == IN_B) ? 8'h01 : 8'h00;
                4'hA: Out <= (IN_A > IN_B) ? 8'h01 : 8'h00;
                4'hB: Out <= (IN_A < IN_B) ? 8'h01 : 8'h00;
                default: Out <= IN_A;
            endcase
        end
    end
    
    assign OUT_RESULT = Out;
                
endmodule
