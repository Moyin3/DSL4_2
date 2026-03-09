`timescale 1ns / 1ps
module VGA_Sig_Gen(
    input        CLK,
    input [15:0] CONFIG_COLOURS,
    output       DPR_CLK,
    output [14:0] VGA_ADDR,
    input        VGA_DATA,
    output reg   VGA_HS,
    output reg   VGA_VS,
    output [7:0] VGA_COLOUR
);
    assign DPR_CLK = CLK;

    reg [1:0] clk_div = 0;

    always @(posedge CLK)
        clk_div <= clk_div + 1;
    
    wire pix_ena = (clk_div == 2'b10);

    reg [9:0] h_cnt = 0;
    reg [9:0] v_cnt = 0;

    always @(posedge CLK) begin
        if (pix_ena) begin
            if (h_cnt == 799) begin
                h_cnt <= 0;
                if (v_cnt == 524) v_cnt <= 0;
                else v_cnt <= v_cnt + 1;
            end else
                h_cnt <= h_cnt + 1;
        end
    end

    wire hs      = ~((h_cnt >= 656) && (h_cnt < 752));
    wire vs      = ~((v_cnt >= 490) && (v_cnt < 492));
    wire visible =  (h_cnt < 640)   && (v_cnt < 480);

    wire [7:0] FG = CONFIG_COLOURS[15:8];
    wire [7:0] BG = CONFIG_COLOURS[7:0];

    wire [7:0] cell_x = h_cnt[9:2];
    wire [6:0] cell_y = v_cnt[9:2];
    assign VGA_ADDR = {cell_y, cell_x};

    always @(*) begin
        VGA_HS     = hs;
        VGA_VS     = vs;
    end
    
    assign VGA_COLOUR = visible ? (VGA_DATA ? FG : BG) : 8'hFF;

endmodule