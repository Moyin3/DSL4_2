`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.03.2026 09:29:50
// Design Name: 
// Module Name: VGA_Peripheral
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


module VGA_Peripheral(
    input CLK,
    input RESET,
    
    // Bus interface (shared tri-state data bus)
    inout [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input BUS_WE,
    
    output VGA_HS,
    output VGA_VS,
    output [7:0] VGA_COLOUR
    );
    
    //
    // Bus data directoin
    // This peripheral is write-only from the bus side, so we never drive data
    // back onto BUS_DATA. Hold it high-Z at all times.
   
assign BUS_DATA = 8'hZZ;

//
// Internal registers written by the processor over the bus
//

reg [14:0] frame_addr;  // 15-bit address into 256 x 128 frame buffer
reg frame_pixel;        // 1-bit pixel value to write
reg frame_we;           // write-enable pulse for frame buffer
reg [7:0] fg_colour;   
reg [7:0] bg_colour;

always @(posedge CLK) begin
    // Default: no frame buffer write this cycle
    frame_we <= 1'b0;
    
    if (RESET) begin
        frame_addr <= 15'd0;
        frame_pixel <= 1'b0;
        fg_colour <= 8'hE0;
        bg_colour <= 8'h03;
    end else if (BUS_WE) begin
        case (BUS_ADDR)
            8'hB0: frame_addr[7:0] <= BUS_DATA;
            8'hB1:frame_addr[14:8] <= BUS_DATA[6:0];
            8'hB2: begin
                frame_pixel <= BUS_DATA[0];
                frame_we <= 1'b1; 
            
            end
            8'hB3: fg_colour <= BUS_DATA;
            8'hB4: bg_colour <= BUS_DATA;
        endcase
    end
end

wire frame_data_out;
wire [14:0] vga_addr;

Frame_Buffer fb (
    .A_CLK(CLK),
    .A_ADDR(frame_addr),
    .A_DATA_IN(frame_pixel),
    .A_DATA_OUT(),
    .A_WE(frame_we),
    .B_CLK(CLK),
    .B_ADDR(vga_addr),
    .B_DATA(frame_data_out)
);

VGA_Sig_Gen vga (
    .CLK(CLK),
    .CONFIG_COLOURS({fg_colour, bg_colour}),
    .DPR_CLK(),
    .VGA_ADDR(vga_addr),
    .VGA_DATA(frame_data_out),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_COLOUR(VGA_COLOUR)
);
endmodule
