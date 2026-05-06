`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/22 11:10:02
// Design Name: 
// Module Name: lcd_bar
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lcd_ctrl(
input wire       clk_in,
input wire       sys_rst_n,
input wire[23:0] data_in,

output wire       data_req,
output wire[10:0] pix_x,
output wire[10:0] pix_y,
output wire[23:0] rgb_lcd_24b,
output wire       hsync,
output wire       vsync,
output wire       lcd_clk,
output wire       lcd_de,
output wire       lcd_bl
    );
    
parameter H_BLANK = 46,
           H_DISP = 800,
           H_FRONT= 210,
           H_PT   = 1056;
parameter V_BLANK = 23,
           V_DISP = 480,
           V_FRONT = 22,
           V_PT = 525;
           
parameter  H_PIXEL = 11'd800,
            V_PIXEL = 11'd480;

wire    data_valid;
wire [23:0] data_out;

reg[11:0] cnt_h;
reg[9:0] cnt_v;

assign lcd_clk =clk_in;
assign lcd_de = data_valid;
assign lcd_bl = 1'b0;

always@(posedge clk_in or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)
        cnt_h <= 'd0;
    else if(cnt_h == H_PT - 1'b1)
        cnt_h <= 'd0;
    else
        cnt_h <= cnt_h +1'b1;
end

always@(posedge clk_in or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)
        cnt_v <= 'd0;
    else if(cnt_h == H_PT - 1'b1)begin
        if(cnt_v == V_PT -1'b1)
            cnt_v <= 'd0;
        else
            cnt_v <= cnt_v + 1'b1;
    end
    else
    cnt_v <= cnt_v;
end



assign data_valid = ((cnt_h >= H_BLANK)
                   && (cnt_h < (H_BLANK + H_DISP)))
                   && ((cnt_v >= V_BLANK)
                   && (cnt_v < (V_BLANK+ V_DISP)));
                   
assign data_req = ((cnt_h >= H_BLANK- 1'b1)
                   && (cnt_h < (H_BLANK + H_DISP-1'b1)))
                   && ((cnt_v >= V_BLANK)
                   && (cnt_v < (V_BLANK+ V_DISP)));
 
assign pix_x = (data_req == 1'b1)
               ? (cnt_h - (H_BLANK-1'b1)) : 11'h3ff;

assign pix_y = (data_req == 1'b1)
               ? (cnt_v - (V_BLANK)) : 10'h3ff;

assign rgb_lcd_24b = (data_req == 1'b1) ? data_in : 24'h000000;

assign hsync = (cnt_h<=H_BLANK - 1'd1) ? 1'b1 : 1'b0;
assign vsync = (cnt_v <= V_BLANK - 1'd1) ? 1'b1 : 1'b0;     
             
endmodule          

module lcd_pic(
    input   wire       clk_in,
    input   wire       sys_rst_n,
    input   wire [10:0] pix_x    ,
    input   wire [10:0] pix_y ,
    output  reg [23:0] pix_data
   // output  reg [25:0] counter = 0,
   //         reg color =0
);
reg [26:0] lcd_counter;
reg [4:0]  lcd_cnt;
parameter  RED      = 24'hFF0000,
            ORANGE  = 24'hFFA500,
            YELLOW  = 24'hFFFF00,
            GREEN   = 24'h008000,
            CYAN    = 24'h00FFFF,
            BLUE    = 24'h0000FF,
            PURPULE = 24'h800080,
            BLACK   = 24'h000000,
            WHITE   = 24'hFFFFFF,
            GRAY    = 24'hBEBEBE,
            TEAL    = 24'h008080,
            Turquoise = 24'h40e0d0,
            DEEPPINK = 24'hFF1493;
            
parameter H_VALID = 800;
parameter BOX_X = 375,   // 시작 x
           BOTTOM    = 480 - 50,   // 시작 y
           BOX_SIZE = 30;
/*------------------------*/
parameter FALL_SPEED = 27'd3_300_000; // 1초에 1픽셀씩
reg [26:0] clk_div;
reg        fall_tick;  // 1클럭짜리 펄스

 /*------------------------*/
 always@(posedge clk_in or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        clk_div   <= 0;
        fall_tick <= 0;
    end else if(clk_div == FALL_SPEED - 1) begin
        clk_div   <= 0;
        fall_tick <= 1;
    end else begin
        clk_div   <= clk_div + 1;
        fall_tick <= 0;
    end
end

localparam IDLE    = 2'd0,
           FALLING = 2'd1,
           LANDED  = 2'd2;

reg [1:0]  state;
reg [10:0] box_y;   // 블록 현재 y위치

always@(posedge clk_in or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        state <= IDLE;
        box_y <= 0;
    end else begin
        case(state)
            IDLE: begin
                box_y <= 0;
                state <= FALLING;   // 바로 시작
            end

            FALLING: begin
                if(fall_tick) begin
                    if(box_y >= BOTTOM)
                        state <= LANDED;
                    else
                        box_y <= box_y + 1;  // 1픽셀씩 내려옴
                end
            end

            LANDED: begin
                // 바닥에서 멈춤
                box_y <= BOTTOM;
            end

            default: state <= IDLE;
        endcase
    end
end


always@(posedge clk_in or negedge sys_rst_n)begin
    if(sys_rst_n  == 1'b0)
        pix_data <=24'd0;
    else if((pix_x >= BOX_X)        && (pix_x < BOX_X + BOX_SIZE) &&
            (pix_y >= box_y)         && (pix_y < box_y + BOX_SIZE))
        pix_data <= GREEN;
    else
        pix_data <= BLACK;
end
/*------------------------*/
        
/*------------------------*/
endmodule



module lcd_colorbar_top(
    input wire sys_clk ,
    input wire sys_rst_n ,
    
    output wire[23:0] rgb_lcd,   
    output wire       hsync,
    output wire       vsync,
    output wire       lcd_clk,
    output wire       lcd_de,
    output wire       lcd_ud,
    output wire       lcd_bl
 );
    wire lcd_clk_33m ;
    wire locked;
    wire rst_n;
    wire [9:0]pix_x;
    wire [9:0]pix_y;
    wire [23:0]pix_data;

assign rst_n = (sys_rst_n & locked);
assign lcd_ud = 1'b0;

clk_wiz_0 clk_wiz_0_inst(
    .clk_out1(lcd_clk_33m),     
    
    // 2. 리셋: IP는 보통 리셋이 1(High)일 때 멈춥니다. 
    // 우리 보드 리셋(sys_rst_n)이 0일 때 눌린 거라면, ~를 붙여서 반전시켜 줍니다.
    .reset(~sys_rst_n), 
    
    // 3. 잠금 신호: 클럭이 안정되면 1이 됩니다. 이미 선언된 locked 와이어에 연결합니다.
    .locked(locked),       
    
    // 4. 입력 클럭: 보드에서 들어오는 실제 100MHz(혹은 50MHz) 원천 클럭을 넣습니다.
    .clk_in1(sys_clk)     // input clk_in1
 );
 
lcd_ctrl lcd_ctrl_inst(
    .clk_in (lcd_clk_33m),
    .sys_rst_n (rst_n),
    .data_in (pix_data),
    .data_req (data_req),
    .pix_x (pix_x),
    .pix_y (pix_y),
    .rgb_lcd_24b (rgb_lcd),
    .hsync (hsync),
    .vsync (vsync),
    .lcd_clk (lcd_clk),
    .lcd_de (lcd_de),
    .lcd_bl (lcd_bl)
 );
 
 lcd_pic lcd_pic_inst(
        .clk_in     (lcd_clk_33m),
        .sys_rst_n  (rst_n),
        .pix_x      (pix_x),
        .pix_y      (pix_y),
        .pix_data   (pix_data)
 );
    

endmodule