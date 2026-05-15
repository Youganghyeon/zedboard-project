`timescale 1ns / 1ps

module lcd_colorbar_top (
    input  wire        sys_clk,
    input  wire        sys_rst_n,

    output wire [23:0] rgb_lcd,
    output wire        hsync,
    output wire        vsync,
    output wire        lcd_clk,
    output wire        lcd_de,
    output wire        lcd_ud,
    output wire        lcd_bl,

    input  wire [3:0]  key_in
);

//------------------------------------------------------------
// CLOCK
//------------------------------------------------------------
wire lcd_clk_33m;
wire locked;
wire rst_n;

assign rst_n  = sys_rst_n & locked;
assign lcd_ud = 1'b0;
assign lcd_bl = 1'b0;
assign lcd_clk = lcd_clk_33m;

clk_wiz_0 clk_wiz_inst (
    .clk_out1 (lcd_clk_33m),
    .reset    (~sys_rst_n),
    .locked   (locked),
    .clk_in1  (sys_clk)
);

//------------------------------------------------------------
// LCD TIMING
//------------------------------------------------------------
wire        data_valid;
wire        data_req;
wire [10:0] pix_x;
wire [10:0] pix_y;

lcd_timing u_lcd_timing (
    .clk        (lcd_clk_33m),
    .rst_n      (rst_n),
    .data_valid (data_valid),
    .data_req   (data_req),
    .pix_x      (pix_x),
    .pix_y      (pix_y),
    .hsync      (hsync),
    .vsync      (vsync)
);

assign lcd_de = data_valid;

//------------------------------------------------------------
// FIELD CALC
//------------------------------------------------------------
wire        inside_field;
wire        out;
wire        out_really;
wire        border_left, border_right, border_up, border_down;
wire [10:0] w_mod, h_mod;
wire [3:0]  w_div;
wire [5:0]  h_div;

field_calc u_field_calc (
    .pix_x        (pix_x),
    .pix_y        (pix_y),
    .inside_field (inside_field),
    .out          (out),
    .out_really   (out_really),
    .border_left  (border_left),
    .border_right (border_right),
    .border_up    (border_up),
    .border_down  (border_down),
    .w_mod        (w_mod),
    .h_mod        (h_mod),
    .w_div        (w_div),
    .h_div        (h_div)
);

//------------------------------------------------------------
// GAME LOGIC
//------------------------------------------------------------
wire [3:0] block_x;
wire [5:0] block_y;
wire       map_bit;

game_logic u_game_logic (
    .clk     (lcd_clk_33m),
    .rst_n   (rst_n),
    .key_in  (key_in),
    .block_x (block_x),
    .block_y (block_y),
    .rd_h    (h_div),
    .rd_w    (w_div),
    .map_bit (map_bit)
);

//------------------------------------------------------------
// 렌더링용 신호 계산
//------------------------------------------------------------
wire inside_block;
wire inside_fixed_block;

assign inside_block =
    inside_field &&
    (w_div == block_x || w_div == block_x + 1) &&
    (h_div == block_y || h_div == block_y - 1);

assign inside_fixed_block =
    inside_field && map_bit;

//------------------------------------------------------------
// RENDERER
//------------------------------------------------------------
wire [23:0] pix_data;

renderer u_renderer (
    .clk               (lcd_clk_33m),
    .data_req          (data_req),
    .out_really        (out_really),
    .out               (out),
    .w_mod             (w_mod),
    .h_mod             (h_mod),
    .inside_block      (inside_block),
    .inside_fixed_block(inside_fixed_block),
    .pix_data          (pix_data)
);

//------------------------------------------------------------
// LCD 출력
//------------------------------------------------------------
assign rgb_lcd = data_valid ? pix_data : 24'h000000;

endmodule