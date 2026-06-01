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

`define TETRIS_W       10   // block width count
`define TETRIS_H       22   // block height count

`define FIELD_SIZE     20   // block size 
`define OUTER_BORDER   4    // field outline
 
 // tetris map Width middle point : 400   
`define FIELD_START_W  300  // tetris map Width end  
`define FIELD_END_W    500  // tetris map Width end

`define FIELD_START_H  20   //  tetris map Height start
`define FIELD_END_H    460  //  tetris map Height end 

//------------------------------------------------------------
// 필드 경계
//------------------------------------------------------------
wire out_left;
wire out_right;
wire out_up;
wire out_down;


assign out_left  = pix_x < `FIELD_START_W;  // isoutLeftField?.  pix_x<300 -> out_left = true
assign out_right = pix_x >= `FIELD_END_W;   //isoutRightField?.  pix_x>=500 -> out_right = true
assign out_up    = pix_y < `FIELD_START_H;  //isoutUpField?.     pix_x<20 -> out_up = true
assign out_down  = pix_y >= `FIELD_END_H;  //isoutDownField?.    pix_x<480 -> out_down = true

assign out = out_left || out_right || out_up || out_down; // out =  isOutField?
assign inside_field = !out;                                // inside_field = isInField?

//------------------------------------------------------------
// 테두리
//------------------------------------------------------------

assign border_left =
    out_left && (pix_x >= `FIELD_START_W - `OUTER_BORDER);
//(pix_x>=300-4) && (pix_x<300) -> FieldLineLeft
assign border_right =
    out_right && (pix_x < `FIELD_END_W + `OUTER_BORDER);
//(pix_x<500+4) && (pix_x>=500) -> FieldLineRight
assign border_up =
    out_up && (pix_y >= `FIELD_START_H - `OUTER_BORDER);
//(pix_y>=20-4) && (pix_x<20) -> FieldLineUp
assign border_down =
    out_down && (pix_y < `FIELD_END_H + `OUTER_BORDER);
//(pix_y<480+4) && (pix_x<480) -> FieldLineDown 
assign out_really =
    (out_left  && ~border_left ) ||
    (out_right && ~border_right) ||
    (out_up    && ~border_up   ) ||
    (out_down  && ~border_down );
//  (pix_x<300) and (pix_x<300-4 or pix_x>=300) -> (pix_x<300-4)  Field 내측 기준 left
//                              ..                                Field 내측 기준 Right
//                              ..                                Field 내측 기준 Up
//                              ..                                Field 내측 기준 Down
//------------------------------------------------------------
// 그리드
//------------------------------------------------------------
assign w_mod =
    inside_field ?
    ((pix_x - `FIELD_START_W) % `FIELD_SIZE) : 0;
//  if(inside_field == true) -> w_mod = (pix_x - 300)  %20  not w_mod = 0  
assign h_mod =
    inside_field ?
    ((pix_y - `FIELD_START_H) % `FIELD_SIZE) : 0;
//  if(inside_field == true) -> h_mod = (pix_y - 20)  %20  not h_mod = 0 
assign w_div =
    inside_field ?
    ((pix_x - `FIELD_START_W) / `FIELD_SIZE) : 0;
//  if(inside_field == true) -> w_div = (pix_y - 300)  %20  not h_mod = 0 
assign h_div =
    inside_field ?
    (`TETRIS_H - 1 - ((pix_y - `FIELD_START_H) / `FIELD_SIZE)) : 0;
//  if(inside_field == true) -> h_mod = (22-1-(pix_y - 20))  %20  not h_mod = 0 
endmodule