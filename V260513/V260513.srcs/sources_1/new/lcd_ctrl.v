`timescale 1ns / 1ps

module lcd_colorbar_top(
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

//============================================================
// CLOCK
//============================================================
wire lcd_clk_33m;
wire locked;
wire rst_n;

assign rst_n  = sys_rst_n & locked;
assign lcd_ud = 1'b0;

clk_wiz_0 clk_wiz_inst (
    .clk_out1 (lcd_clk_33m),
    .reset    (~sys_rst_n),
    .locked   (locked),
    .clk_in1  (sys_clk)
);

//============================================================
// LCD TIMING
//============================================================
parameter H_BLANK = 46;
parameter H_DISP  = 800;
parameter H_TOTAL = 1056;

parameter V_BLANK = 23;
parameter V_DISP  = 480;
parameter V_TOTAL = 525;

reg [11:0] cnt_h;
reg [9:0]  cnt_v;

always @(posedge lcd_clk_33m or negedge rst_n) begin

    if (!rst_n) begin
        cnt_h <= 0;
        cnt_v <= 0;
    end

    else if (cnt_h == H_TOTAL - 1) begin

        cnt_h <= 0;

        if (cnt_v == V_TOTAL - 1)
            cnt_v <= 0;
        else
            cnt_v <= cnt_v + 1;

    end

    else begin
        cnt_h <= cnt_h + 1;
    end

end

wire data_valid;
wire data_req;

assign data_valid =
    (cnt_h >= H_BLANK) &&
    (cnt_h < H_BLANK + H_DISP) &&
    (cnt_v >= V_BLANK) &&
    (cnt_v < V_BLANK + V_DISP);

assign data_req =
    (cnt_h >= H_BLANK - 1) &&
    (cnt_h < H_BLANK + H_DISP - 1) &&
    (cnt_v >= V_BLANK) &&
    (cnt_v < V_BLANK + V_DISP);

wire [10:0] pix_x;
wire [10:0] pix_y;

assign pix_x =
    data_req ? (cnt_h - (H_BLANK - 1)) : 11'h3ff;

assign pix_y =
    data_req ? (cnt_v - V_BLANK) : 11'h3ff;

reg [23:0] pix_data;

assign lcd_clk = lcd_clk_33m;
assign lcd_de  = data_valid;
assign lcd_bl  = 1'b0;

assign rgb_lcd =
    data_valid ? pix_data : 24'h000000;

assign hsync = (cnt_h <= H_BLANK - 1);
assign vsync = (cnt_v <= V_BLANK - 1);

//============================================================
// FIELD
//============================================================
`define TETRIS_W       10
`define TETRIS_H       22

`define FIELD_SIZE     20
`define OUTER_BORDER   4

`define FIELD_START_W  300
`define FIELD_END_W    500

`define FIELD_START_H  20
`define FIELD_END_H    460

wire out_left;
wire out_right;
wire out_up;
wire out_down;

assign out_left  = pix_x < `FIELD_START_W;
assign out_right = pix_x >= `FIELD_END_W;
assign out_up    = pix_y < `FIELD_START_H;
assign out_down  = pix_y >= `FIELD_END_H;

wire border_left;
wire border_right;
wire border_up;
wire border_down;

assign border_left =
    out_left &&
    (pix_x >= `FIELD_START_W - `OUTER_BORDER);

assign border_right =
    out_right &&
    (pix_x < `FIELD_END_W + `OUTER_BORDER);

assign border_up =
    out_up &&
    (pix_y >= `FIELD_START_H - `OUTER_BORDER);

assign border_down =
    out_down &&
    (pix_y < `FIELD_END_H + `OUTER_BORDER);

wire out;
wire out_really;

assign out =
    out_left || out_right || out_up || out_down;

assign out_really =
    (out_left  && ~border_left ) ||
    (out_right && ~border_right) ||
    (out_up    && ~border_up   ) ||
    (out_down  && ~border_down );

//============================================================
// GRID
//============================================================
wire [10:0] w_mod;
wire [10:0] h_mod;

assign w_mod =
    (pix_x - `FIELD_START_W) % `FIELD_SIZE;

assign h_mod =
    (pix_y - `FIELD_START_H) % `FIELD_SIZE;

wire [3:0] w_div;
wire [5:0] h_div;

assign w_div =
    (pix_x - `FIELD_START_W) / `FIELD_SIZE;

assign h_div =
    `TETRIS_H - 1 -
    ((pix_y - `FIELD_START_H) / `FIELD_SIZE);

//============================================================
// BLOCK
//============================================================
reg [3:0] block_x;
reg [5:0] block_y;

initial begin
    block_x = 4;
    block_y = 20;
end

wire inside_block;

assign inside_block =
    (w_div == block_x || w_div == block_x + 1) &&
    (h_div == block_y || h_div == block_y - 1);

//============================================================
// DROP CLOCK
//============================================================
reg [25:0] drop_counter;
reg drop_clk;

always @(posedge lcd_clk_33m or negedge rst_n) begin

    if (!rst_n) begin
        drop_counter <= 0;
        drop_clk <= 0;
    end

    else begin

        drop_counter <= drop_counter + 1;

        if (drop_counter == 26'd33000000) begin
            drop_counter <= 0;
            drop_clk <= 1;
        end

        else begin
            drop_clk <= 0;
        end

    end

end

//============================================================
// BLOCK MOVE
//============================================================
always @(posedge lcd_clk_33m or negedge rst_n) begin

    if (!rst_n) begin
        block_x <= 4;
        block_y <= 20;
    end

    else begin

        if (drop_clk) begin

            if (block_y > 1)
                block_y <= block_y - 1;

        end

        // LEFT
        if (~key_in[1]) begin

            if (block_x > 0)
                block_x <= block_x - 1;

        end

        // RIGHT
        if (~key_in[3]) begin

            if (block_x < 8)
                block_x <= block_x + 1;

        end

    end

end

//============================================================
// RENDER
//============================================================
always @(posedge lcd_clk_33m) begin

    if (!data_req)
        pix_data <= 24'h000000;

    else if (out_really)
        pix_data <= 24'h808080;

    else if (out)
        pix_data <= 24'h800000;

    else if (
        w_mod == 0 ||
        h_mod == 0 ||
        w_mod == (`FIELD_SIZE - 1) ||
        h_mod == (`FIELD_SIZE - 1)
    )
        pix_data <= 24'h008080;

    else if (inside_block)
        pix_data <= 24'hFFFF00;

    else
        pix_data <= 24'hFFFFFF;

end

endmodule