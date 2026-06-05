`timescale 1ns / 1ps

//====================================================
// LCD Controller
//====================================================
module lcd_ctrl(
    input  wire        clk_in,
    input  wire        sys_rst_n,
    input  wire [23:0] data_in,

    output wire        data_req,
    output wire [10:0] pix_x,
    output wire [10:0] pix_y,
    output wire [23:0] rgb_lcd_24b,
    output wire        hsync,
    output wire        vsync,
    output wire        lcd_clk,
    output wire        lcd_de,
    output wire        lcd_bl
);

parameter H_BLANK = 46,
          H_DISP  = 800,
          H_FRONT = 210,
          H_PT    = 1056;

parameter V_BLANK = 23,
          V_DISP  = 480,
          V_FRONT = 22,
          V_PT    = 525;

reg [11:0] cnt_h;
reg [9:0]  cnt_v;

wire data_valid;

assign lcd_clk = clk_in;
assign lcd_de  = data_valid;
assign lcd_bl  = 1'b0;

always @(posedge clk_in or negedge sys_rst_n) begin
    if(!sys_rst_n)
        cnt_h <= 0;
    else if(cnt_h == H_PT - 1)
        cnt_h <= 0;
    else
        cnt_h <= cnt_h + 1;
end

always @(posedge clk_in or negedge sys_rst_n) begin
    if(!sys_rst_n)
        cnt_v <= 0;
    else if(cnt_h == H_PT - 1) begin
        if(cnt_v == V_PT - 1)
            cnt_v <= 0;
        else
            cnt_v <= cnt_v + 1;
    end
end

assign data_valid =
    (cnt_h >= H_BLANK) &&
    (cnt_h < H_BLANK + H_DISP) &&
    (cnt_v >= V_BLANK) &&
    (cnt_v < V_BLANK + V_DISP);

assign data_req = data_valid;

assign pix_x =
    data_valid ? (cnt_h - H_BLANK) : 11'd0;

assign pix_y =
    data_valid ? (cnt_v - V_BLANK) : 11'd0;

assign rgb_lcd_24b =
    data_valid ? data_in : 24'h000000;

assign hsync =
    (cnt_h <= H_BLANK - 1) ? 1'b1 : 1'b0;

assign vsync =
    (cnt_v <= V_BLANK - 1) ? 1'b1 : 1'b0;

endmodule


//====================================================
// Score Picture
//====================================================
module score_pic(
    input  wire        clk_in,
    input  wire        sys_rst_n,
    input  wire [10:0] pix_x,
    input  wire [10:0] pix_y,
    output reg  [23:0] pix_data
);

parameter BLACK  = 24'h000000;
parameter WHITE  = 24'hFFFFFF;
parameter GOLD   = 24'hFFD700;
parameter DARK   = 24'h202020;
parameter BLUEBG = 24'h101830;

//--------------------------------------------
// 1 second counter
//--------------------------------------------
parameter CLK_FREQ = 33_000_000;

reg [25:0] clk_cnt;
reg [15:0] score;

always @(posedge clk_in or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        clk_cnt <= 0;
        score   <= 0;
    end
    else begin
        if(clk_cnt == CLK_FREQ - 1) begin
            clk_cnt <= 0;

            if(score < 9999)
                score <= score + 100;
        end
        else begin
            clk_cnt <= clk_cnt + 1;
        end
    end
end

//--------------------------------------------
// digits
//--------------------------------------------
wire [3:0] d3;
wire [3:0] d2;
wire [3:0] d1;
wire [3:0] d0;

assign d3 = score / 1000;
assign d2 = (score % 1000) / 100;
assign d1 = (score % 100) / 10;
assign d0 = score % 10;

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
    input [6:0] seg;

    begin
        seg_pixel =
            (seg[0] && (y < 4) && (x > 3) && (x < 20)) ||
            (seg[1] && (x > 19) && (y > 3)  && (y < 18)) ||
            (seg[2] && (x > 19) && (y > 21) && (y < 36)) ||
            (seg[3] && (y > 35) && (x > 3)  && (x < 20)) ||
            (seg[4] && (x < 4)  && (y > 21) && (y < 36)) ||
            (seg[5] && (x < 4)  && (y > 3)  && (y < 18)) ||
            (seg[6] && (y > 17) && (y < 22) && (x > 3) && (x < 20));
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

wire [10:0] ly = pix_y - START_Y;

//--------------------------------------------
// active area
//--------------------------------------------
wire in0 =
    (pix_x >= START_X) &&
    (pix_x < START_X + DIGIT_W) &&
    (pix_y >= START_Y) &&
    (pix_y < START_Y + DIGIT_H);

wire in1 =
    (pix_x >= START_X + GAP) &&
    (pix_x < START_X + GAP + DIGIT_W) &&
    (pix_y >= START_Y) &&
    (pix_y < START_Y + DIGIT_H);

wire in2 =
    (pix_x >= START_X + GAP*2) &&
    (pix_x < START_X + GAP*2 + DIGIT_W) &&
    (pix_y >= START_Y) &&
    (pix_y < START_Y + DIGIT_H);

wire in3 =
    (pix_x >= START_X + GAP*3) &&
    (pix_x < START_X + GAP*3 + DIGIT_W) &&
    (pix_y >= START_Y) &&
    (pix_y < START_Y + DIGIT_H);

//--------------------------------------------
// segment on
//--------------------------------------------
wire seg0 =
    in0 && seg_pixel(lx0, ly, seg7(d3));

wire seg1 =
    in1 && seg_pixel(lx1, ly, seg7(d2));

wire seg2 =
    in2 && seg_pixel(lx2, ly, seg7(d1));

wire seg3 =
    in3 && seg_pixel(lx3, ly, seg7(d0));

//--------------------------------------------
// draw
//--------------------------------------------
always @(posedge clk_in or negedge sys_rst_n) begin
    if(!sys_rst_n)
        pix_data <= BLACK;

    else begin

        // game area
        if(pix_x < 560)
            pix_data <= BLACK;

        // score panel
        else
            pix_data <= BLUEBG;

        // segments
        if(seg0 || seg1 || seg2 || seg3)
            pix_data <= GOLD;
    end
end

endmodule


//====================================================
// TOP
//====================================================
module score_display(
    input  wire        sys_clk,
    input  wire        sys_rst_n,

    output wire [23:0] rgb_lcd,
    output wire        hsync,
    output wire        vsync,
    output wire        lcd_clk,
    output wire        lcd_de,
    output wire        lcd_ud,
    output wire        lcd_bl
);

wire lcd_clk_33m;
wire locked;
wire rst_n;

wire data_req;

wire [10:0] pix_x;
wire [10:0] pix_y;

wire [23:0] pix_data;

assign rst_n  = sys_rst_n & locked;
assign lcd_ud = 1'b0;

//--------------------------------------------
// Clock Wizard
//--------------------------------------------
clk_wiz_0 clk_wiz_0_inst(
    .clk_out1(lcd_clk_33m),
    .reset(~sys_rst_n),
    .locked(locked),
    .clk_in1(sys_clk)
);

//--------------------------------------------
// LCD CTRL
//--------------------------------------------
lcd_ctrl lcd_ctrl_inst(
    .clk_in(lcd_clk_33m),
    .sys_rst_n(rst_n),
    .data_in(pix_data),

    .data_req(data_req),
    .pix_x(pix_x),
    .pix_y(pix_y),

    .rgb_lcd_24b(rgb_lcd),
    .hsync(hsync),
    .vsync(vsync),
    .lcd_clk(lcd_clk),
    .lcd_de(lcd_de),
    .lcd_bl(lcd_bl)
);

//--------------------------------------------
// Renderer
//--------------------------------------------
score_pic score_pic_inst(
    .clk_in(lcd_clk_33m),
    .sys_rst_n(rst_n),
    .pix_x(pix_x),
    .pix_y(pix_y),
    .pix_data(pix_data)
);

endmodule