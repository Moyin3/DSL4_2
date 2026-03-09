`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.02.2026 11:35:51
// Design Name: 
// Module Name: Complete_System_Top
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


module Complete_System_Top(
    input CLK,
    input RESET,
    
    output VGA_HS,
    output VGA_VS,
    output [7:0] VGA_COLOUR
    );
    
wire [7:0] BUS_DATA;
wire [7:0] BUS_ADDR;
wire BUS_WE;

//
// ROM has its own point-to-point connection to the processor
//

wire [7:0] ROM_ADDR;
wire [7:0] ROM_DATA;

wire [1:0] INTERRUPT_RAISE;
wire [1:0] INTERRUPT_ACK;

assign INTERRUPT_RAISE[0] = 1'b0; // no mouse peripheral in this assignment
Processor cpu (
    .CLK(CLK),
    .RESET(RESET),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),
    
    .ROM_ADDRESS(ROM_ADDR),
    .ROM_DATA(ROM_DATA),
    
    .BUS_INTERRUPTS_RAISE(INTERRUPT_RAISE),
    .BUS_INTERRUPTS_ACK(INTERRUPT_ACK)
);

RAM ram (
    .CLK(CLK),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE)
);


ROM rom (
    .CLK(CLK),
    .ADDR(ROM_ADDR),
    .DATA(ROM_DATA)
);

Timer timer (
    .CLK(CLK),
    .RESET(RESET),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),
    .BUS_INTERRUPT_RAISE(INTERRUPT_RAISE[1]),
    .BUS_INTERRUPT_ACK(INTERRUPT_ACK[1])
);


VGA_Peripheral vga_periph (
    .CLK(CLK),
    .RESET(RESET),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_COLOUR(VGA_COLOUR)
);


endmodule
