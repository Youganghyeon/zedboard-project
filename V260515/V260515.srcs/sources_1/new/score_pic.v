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

parameter SCALE = 3;

localparam DIGIT_W = 6  * SCALE;
localparam DIGIT_H = 10 * SCALE;
localparam GAP     = 8  * SCALE;
localparam START_X = 620;
localparam START_Y = 200;

localparam T  = 1 * SCALE;
localparam M1 = 4 * SCALE;
localparam M2 = 6 * SCALE;
localparam B  = 9 * SCALE;
localparam R  = 5 * SCALE;

wire [3:0] d3 = score / 1000;
wire [3:0] d2 = (score % 1000) / 100;
wire [3:0] d1 = (score % 100)  / 10;
wire [3:0] d0 = score % 10;

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

wire [10:0] lx0 = pix_x - START_X;
wire [10:0] lx1 = pix_x - (START_X + GAP);
wire [10:0] lx2 = pix_x - (START_X + GAP*2);
wire [10:0] lx3 = pix_x - (START_X + GAP*3);
wire [10:0] ly  = pix_y - START_Y;

// ★ 미러링 좌표 추가
wire [10:0] mlx0 = (DIGIT_W - 1) - lx0;
wire [10:0] mlx1 = (DIGIT_W - 1) - lx1;
wire [10:0] mlx2 = (DIGIT_W - 1) - lx2;
wire [10:0] mlx3 = (DIGIT_W - 1) - lx3;

wire in0 = (pix_x >= START_X)         && (pix_x < START_X + DIGIT_W)         && (pix_y >= START_Y) && (pix_y < START_Y + DIGIT_H);
wire in1 = (pix_x >= START_X + GAP)   && (pix_x < START_X + GAP   + DIGIT_W) && (pix_y >= START_Y) && (pix_y < START_Y + DIGIT_H);
wire in2 = (pix_x >= START_X + GAP*2) && (pix_x < START_X + GAP*2 + DIGIT_W) && (pix_y >= START_Y) && (pix_y < START_Y + DIGIT_H);
wire in3 = (pix_x >= START_X + GAP*3) && (pix_x < START_X + GAP*3 + DIGIT_W) && (pix_y >= START_Y) && (pix_y < START_Y + DIGIT_H);

wire [6:0] s0 = seg7(d3);
wire [6:0] s1 = seg7(d2);
wire [6:0] s2 = seg7(d1);
wire [6:0] s3 = seg7(d0);

// digit 0 (d3) - mlx0 사용
wire seg0 = in0 && (
    (s0[0] && (ly <  T)    && (mlx0 <  R))                     ||
    (s0[1] && (mlx0 <  T)  && (ly <  M1))                      ||
    (s0[2] && (mlx0 <  T)  && (ly >= M2) && (ly < B))          ||
    (s0[3] && (ly >= B)    && (mlx0 <  R))                     ||
    (s0[4] && (mlx0 >= R-T) && (ly >= M2) && (ly < B))         ||
    (s0[5] && (mlx0 >= R-T) && (ly <  M1))                     ||
    (s0[6] && (ly >= M1)   && (ly < M2) && (mlx0 < R))
);

// digit 1 (d2) - mlx1 사용
wire seg1 = in1 && (
    (s1[0] && (ly <  T)    && (mlx1 <  R))                     ||
    (s1[1] && (mlx1 <  T)  && (ly <  M1))                      ||
    (s1[2] && (mlx1 <  T)  && (ly >= M2) && (ly < B))          ||
    (s1[3] && (ly >= B)    && (mlx1 <  R))                     ||
    (s1[4] && (mlx1 >= R-T) && (ly >= M2) && (ly < B))         ||
    (s1[5] && (mlx1 >= R-T) && (ly <  M1))                     ||
    (s1[6] && (ly >= M1)   && (ly < M2) && (mlx1 < R))
);

// digit 2 (d1) - mlx2 사용
wire seg2 = in2 && (
    (s2[0] && (ly <  T)    && (mlx2 <  R))                     ||
    (s2[1] && (mlx2 <  T)  && (ly <  M1))                      ||
    (s2[2] && (mlx2 <  T)  && (ly >= M2) && (ly < B))          ||
    (s2[3] && (ly >= B)    && (mlx2 <  R))                     ||
    (s2[4] && (mlx2 >= R-T) && (ly >= M2) && (ly < B))         ||
    (s2[5] && (mlx2 >= R-T) && (ly <  M1))                     ||
    (s2[6] && (ly >= M1)   && (ly < M2) && (mlx2 < R))
);

// digit 3 (d0) - mlx3 사용
wire seg3 = in3 && (
    (s3[0] && (ly <  T)    && (mlx3 <  R))                     ||
    (s3[1] && (mlx3 <  T)  && (ly <  M1))                      ||
    (s3[2] && (mlx3 <  T)  && (ly >= M2) && (ly < B))          ||
    (s3[3] && (ly >= B)    && (mlx3 <  R))                     ||
    (s3[4] && (mlx3 >= R-T) && (ly >= M2) && (ly < B))         ||
    (s3[5] && (mlx3 >= R-T) && (ly <  M1))                     ||
    (s3[6] && (ly >= M1)   && (ly < M2) && (mlx3 < R))
);

localparam PAD    = 4;
localparam BG_X1  = START_X - PAD;
localparam BG_X2  = START_X + GAP*3 + DIGIT_W + PAD;
localparam BG_Y1  = START_Y - PAD;
localparam BG_Y2  = START_Y + DIGIT_H + PAD;

wire label_pixel;
score_label u_label (
    .pix_x    (pix_x),
    .pix_y    (pix_y),
    .pixel_on (label_pixel)
);

always @(posedge clk_in or negedge sys_rst_n) begin
    if (!sys_rst_n)
        pix_data <= BLACK;
    else begin
        if (seg0 || seg1 || seg2 || seg3)
            pix_data <= GOLD;
        else if (label_pixel)
            pix_data <= GOLD;
        else if ((pix_x >= BG_X1) && (pix_x < BG_X2) &&
                 (pix_y >= BG_Y1) && (pix_y < BG_Y2))
            pix_data <= BLUEBG;
        else
            pix_data <= BLACK;
    end
end
endmodule