`timescale 1ns / 1ps

module renderer (
    input  wire        clk,

    input  wire        data_req,

    input  wire        out_really,
    input  wire        out,

    input  wire [10:0] w_mod,
    input  wire [10:0] h_mod,

    input  wire        inside_block,
    input  wire        inside_fixed_block,

    output reg  [23:0] pix_data
);

`define FIELD_SIZE 20

always @(posedge clk) begin

    if (!data_req)
        pix_data <= 24'h000000;         // 화면 밖

    else if (out_really)
        pix_data <= 24'h808080;         // 완전 바깥 (회색)

    else if (out)
        pix_data <= 24'h800000;         // 테두리 (빨간색)

    else if (
        w_mod == 0 ||
        h_mod == 0 ||
        w_mod == (`FIELD_SIZE - 1) ||
        h_mod == (`FIELD_SIZE - 1)
    )
        pix_data <= 24'h008080;         // 그리드 선 (청록)

    else if (inside_block)
        pix_data <= 24'hFFFF00;         // 현재 블록 (노란색)

    else if (inside_fixed_block)
        pix_data <= 24'h00FF00;         // 고정 블록 (초록색)

    else
        pix_data <= 24'hFFFFFF;         // 빈 칸 (흰색)

end

endmodule