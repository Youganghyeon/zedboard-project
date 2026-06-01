`timescale 1ns / 1ps

module score_pic(
    input  wire        clk_in,
    input  wire        sys_rst_n,
    input  wire [10:0] pix_x,
    input  wire [10:0] pix_y,
    input  wire [15:0] score,
    output reg  [23:0] pix_data
);

parameter BLACK  = 24'h000000;
parameter GOLD   = 24'hFFD700;
parameter BLUEBG = 24'h101830;

//--------------------------------------------
// digits
//--------------------------------------------
wire [3:0] d3 = score / 1000;
wire [3:0] d2 = (score % 1000) / 100;
wire [3:0] d1 = (score % 100)  / 10;
wire [3:0] d0 = score % 10;

//--------------------------------------------
// 7segment decoder
//--------------------------------------------
function [6:0] seg7;
    input [3:0] num;
    begin
        case(num)
            0: seg7 = 7'b0111111;
            1: seg7 = 7'b0000110;
            2: seg7 = 7'b1011011;
            3: seg7 = 7'b1001111;
            4: seg7 = 7'b1100110;
            5: seg7 = 7'b1101101;
            6: seg7 = 7'b1111101;
            7: seg7 = 7'b0000111;
            8: seg7 = 7'b1111111;
            9: seg7 = 7'b1101111;
            default: seg7 = 7'b0000000;
        endcase
    end
endfunction

//--------------------------------------------
// segment pixel
//--------------------------------------------
function seg_pixel;
    input [10:0] x;
    input [10:0] y;
    input [6:0]  seg;
    begin
        seg_pixel =
            (seg[0] && (y <  4) && (x >  3) && (x < 20)) ||
            (seg[1] && (x > 19) && (y >  3) && (y < 18)) ||
            (seg[2] && (x > 19) && (y > 21) && (y < 36)) ||
            (seg[3] && (y > 35) && (x >  3) && (x < 20)) ||
            (seg[4] && (x <  4) && (y > 21) && (y < 36)) ||
            (seg[5] && (x <  4) && (y >  3) && (y < 18)) ||
            (seg[6] && (y > 17) && (y < 22) && (x >  3) && (x < 20));
    end
endfunction

//--------------------------------------------
// digit positions
//--------------------------------------------
parameter DIGIT_W = 24;
parameter DIGIT_H = 40;
parameter START_X = 580;
parameter START_Y = 200;
parameter GAP     = 30;

//--------------------------------------------
// local coords
//--------------------------------------------
wire [10:0] lx0 = pix_x - START_X;
wire [10:0] lx1 = pix_x - (START_X + GAP);
wire [10:0] lx2 = pix_x - (START_X + GAP*2);
wire [10:0] lx3 = pix_x - (START_X + GAP*3);
wire [10:0] ly  = pix_y - START_Y;

//--------------------------------------------
// active area
//--------------------------------------------
wire in0 = (pix_x >= START_X)         && (pix_x < START_X + DIGIT_W)         && (pix_y >= START_Y) && (pix_y < START_Y + DIGIT_H);
wire in1 = (pix_x >= START_X + GAP)   && (pix_x < START_X + GAP   + DIGIT_W) && (pix_y >= START_Y) && (pix_y < START_Y + DIGIT_H);
wire in2 = (pix_x >= START_X + GAP*2) && (pix_x < START_X + GAP*2 + DIGIT_W) && (pix_y >= START_Y) && (pix_y < START_Y + DIGIT_H);
wire in3 = (pix_x >= START_X + GAP*3) && (pix_x < START_X + GAP*3 + DIGIT_W) && (pix_y >= START_Y) && (pix_y < START_Y + DIGIT_H);

//--------------------------------------------
// segment on
//--------------------------------------------
wire seg0 = in0 && seg_pixel(lx0, ly, seg7(d3));
wire seg1 = in1 && seg_pixel(lx1, ly, seg7(d2));
wire seg2 = in2 && seg_pixel(lx2, ly, seg7(d1));
wire seg3 = in3 && seg_pixel(lx3, ly, seg7(d0));

//--------------------------------------------
// draw
//--------------------------------------------
always @(posedge clk_in or negedge sys_rst_n) begin
    if (!sys_rst_n)
        pix_data <= BLACK;
    else begin
        if (pix_x < 500)
            pix_data <= BLACK;        // 게임 영역은 renderer가 담당
        else
            pix_data <= BLUEBG;       // 점수 패널 배경

        if (seg0 || seg1 || seg2 || seg3)
            pix_data <= GOLD;         // 세그먼트 숫자
    end
end

endmodule