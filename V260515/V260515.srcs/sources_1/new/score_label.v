// score_label.v
// "SCORE" 텍스트 표시 모듈 (8x16 폰트)
`timescale 1ns / 1ps
module score_label(
    input  wire [10:0] pix_x,
    input  wire [10:0] pix_y,
    output reg         pixel_on
);

// "SCORE" 시작 위치 (숫자 위쪽)
parameter LABEL_X = 620;
parameter LABEL_Y = 175;   // 숫자(START_Y=200)보다 위
parameter CHAR_W  = 8;
parameter CHAR_H  = 16;

// 로컬 좌표
wire [10:0] lx = pix_x - LABEL_X;
wire [10:0] ly = pix_y - LABEL_Y;

// 현재 픽셀이 SCORE 영역 안인지
wire in_label = (pix_x >= LABEL_X) && (pix_x < LABEL_X + CHAR_W*5) &&
                (pix_y >= LABEL_Y) && (pix_y < LABEL_Y + CHAR_H);

// 몇 번째 글자인지 (0=S, 1=C, 2=O, 3=R, 4=E)
wire [2:0] char_idx = lx[6:3];   // lx / 8
// 글자 내 x 픽셀 (0~7)
wire [2:0] char_x   = lx[2:0];
// 글자 내 y 행 (0~15)
wire [3:0] char_y   = ly[3:0];

// 각 문자의 각 행 비트맵
function [7:0] font_row;
    input [2:0] ch;   // 글자 인덱스
    input [3:0] row;  // 행 (0~15)
    begin
        case (ch)
        // S (0x53)
        3'd0: case(row)
            4'h0: font_row = 8'b00000000;
            4'h1: font_row = 8'b00000000;
            4'h2: font_row = 8'b01111100;
            4'h3: font_row = 8'b11000110;
            4'h4: font_row = 8'b11000110;
            4'h5: font_row = 8'b01100000;
            4'h6: font_row = 8'b00111000;
            4'h7: font_row = 8'b00001100;
            4'h8: font_row = 8'b00000110;
            4'h9: font_row = 8'b11000110;
            4'ha: font_row = 8'b11000110;
            4'hb: font_row = 8'b01111100;
            default: font_row = 8'b00000000;
        endcase
        // C (0x43)
        3'd1: case(row)
            4'h0: font_row = 8'b00000000;
            4'h1: font_row = 8'b00000000;
            4'h2: font_row = 8'b00111100;
            4'h3: font_row = 8'b01100110;
            4'h4: font_row = 8'b11000010;
            4'h5: font_row = 8'b11000000;
            4'h6: font_row = 8'b11000000;
            4'h7: font_row = 8'b11000000;
            4'h8: font_row = 8'b11000000;
            4'h9: font_row = 8'b11000010;
            4'ha: font_row = 8'b01100110;
            4'hb: font_row = 8'b00111100;
            default: font_row = 8'b00000000;
        endcase
        // O (0x4F)
        3'd2: case(row)
            4'h0: font_row = 8'b00000000;
            4'h1: font_row = 8'b00000000;
            4'h2: font_row = 8'b01111100;
            4'h3: font_row = 8'b11000110;
            4'h4: font_row = 8'b11000110;
            4'h5: font_row = 8'b11000110;
            4'h6: font_row = 8'b11000110;
            4'h7: font_row = 8'b11000110;
            4'h8: font_row = 8'b11000110;
            4'h9: font_row = 8'b11000110;
            4'ha: font_row = 8'b11000110;
            4'hb: font_row = 8'b01111100;
            default: font_row = 8'b00000000;
        endcase
        // R (0x52)
        3'd3: case(row)
            4'h0: font_row = 8'b00000000;
            4'h1: font_row = 8'b00000000;
            4'h2: font_row = 8'b11111100;
            4'h3: font_row = 8'b01100110;
            4'h4: font_row = 8'b01100110;
            4'h5: font_row = 8'b01100110;
            4'h6: font_row = 8'b01111100;
            4'h7: font_row = 8'b01101100;
            4'h8: font_row = 8'b01100110;
            4'h9: font_row = 8'b01100110;
            4'ha: font_row = 8'b01100110;
            4'hb: font_row = 8'b11100110;
            default: font_row = 8'b00000000;
        endcase
        // E (0x45)
        3'd4: case(row)
            4'h0: font_row = 8'b00000000;
            4'h1: font_row = 8'b00000000;
            4'h2: font_row = 8'b11111110;
            4'h3: font_row = 8'b01100110;
            4'h4: font_row = 8'b01100010;
            4'h5: font_row = 8'b01101000;
            4'h6: font_row = 8'b01111000;
            4'h7: font_row = 8'b01101000;
            4'h8: font_row = 8'b01100000;
            4'h9: font_row = 8'b01100010;
            4'ha: font_row = 8'b01100110;
            4'hb: font_row = 8'b11111110;
            default: font_row = 8'b00000000;
        endcase
        default: font_row = 8'b00000000;
        endcase
    end
endfunction

// 해당 픽셀의 비트 ON/OFF
wire [7:0] row_data = font_row(char_idx, char_y);
// MSB가 왼쪽 픽셀
wire bit_on = row_data[7 - char_x];

always @(*) begin
    pixel_on = in_label && bit_on;
end

endmodule