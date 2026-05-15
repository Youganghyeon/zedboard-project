`timescale 1ns / 1ps

module field_calc (
    input  wire [10:0] pix_x,
    input  wire [10:0] pix_y,

    output wire        inside_field,
    output wire        out,
    output wire        out_really,

    output wire        border_left,
    output wire        border_right,
    output wire        border_up,
    output wire        border_down,

    output wire [10:0] w_mod,
    output wire [10:0] h_mod,
    output wire [3:0]  w_div,
    output wire [5:0]  h_div
);

`define TETRIS_W       10
`define TETRIS_H       22

`define FIELD_SIZE     20
`define OUTER_BORDER   4

`define FIELD_START_W  300
`define FIELD_END_W    500

`define FIELD_START_H  20
`define FIELD_END_H    460

//------------------------------------------------------------
// 필드 경계
//------------------------------------------------------------
wire out_left;
wire out_right;
wire out_up;
wire out_down;

assign out_left  = pix_x < `FIELD_START_W;
assign out_right = pix_x >= `FIELD_END_W;
assign out_up    = pix_y < `FIELD_START_H;
assign out_down  = pix_y >= `FIELD_END_H;

assign out = out_left || out_right || out_up || out_down;
assign inside_field = !out;

//------------------------------------------------------------
// 테두리
//------------------------------------------------------------
assign border_left =
    out_left && (pix_x >= `FIELD_START_W - `OUTER_BORDER);

assign border_right =
    out_right && (pix_x < `FIELD_END_W + `OUTER_BORDER);

assign border_up =
    out_up && (pix_y >= `FIELD_START_H - `OUTER_BORDER);

assign border_down =
    out_down && (pix_y < `FIELD_END_H + `OUTER_BORDER);

assign out_really =
    (out_left  && ~border_left ) ||
    (out_right && ~border_right) ||
    (out_up    && ~border_up   ) ||
    (out_down  && ~border_down );

//------------------------------------------------------------
// 그리드
//------------------------------------------------------------
assign w_mod =
    inside_field ?
    ((pix_x - `FIELD_START_W) % `FIELD_SIZE) : 0;

assign h_mod =
    inside_field ?
    ((pix_y - `FIELD_START_H) % `FIELD_SIZE) : 0;

assign w_div =
    inside_field ?
    ((pix_x - `FIELD_START_W) / `FIELD_SIZE) : 0;

assign h_div =
    inside_field ?
    (`TETRIS_H - 1 - ((pix_y - `FIELD_START_H) / `FIELD_SIZE)) : 0;

endmodule