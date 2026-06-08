`timescale 1ns / 1ps

module game_logic (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [3:0]  key_in,

    output wire [3:0]  cell_x0, cell_x1, cell_x2, cell_x3,
    output wire [5:0]  cell_y0, cell_y1, cell_y2, cell_y3,

    input  wire [5:0]  rd_h,
    input  wire [3:0]  rd_w,
    output wire        map_bit,
    output reg [15:0]  score
);

`define TETRIS_W  10
`define TETRIS_H  22

//------------------------------------------------------------
// FSM
//------------------------------------------------------------
localparam STATE_SPAWN = 3'd0;
localparam STATE_FALL  = 3'd1;
localparam STATE_MERGE = 3'd2;
localparam STATE_CLEAR = 3'd3;

reg [2:0] state;

//------------------------------------------------------------
// MAP
//------------------------------------------------------------
reg [9:0] tetris_map [0:`TETRIS_H-1]; // teteris_map[0:21]

assign map_bit = tetris_map[rd_h][rd_w]; // teteris_map[h_div][w_div]
               
//------------------------------------------------------------
// CLEAR
//------------------------------------------------------------
reg [4:0] clear_row;

//------------------------------------------------------------
// BLOCK STATE
//------------------------------------------------------------
reg [3:0] block_x;
reg [5:0] block_y;
reg [1:0] block_type;
reg [1:0] rotation;

//------------------------------------------------------------
// LFSR
//------------------------------------------------------------
reg [6:0] lfsr;
//random LFSR.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) lfsr <= 7'b1010101;
    else        lfsr <= {lfsr[5:0], lfsr[6] ^ lfsr[5]};
end

wire [1:0] next_type = lfsr[1:0];

//------------------------------------------------------------
// ROM 함수: {type, rot} → 4셀 상대좌표 (rx, ry)
// y는 위가 +, 절대좌표 = block_x+rx, block_y-ry
//------------------------------------------------------------
task get_cells;
    input  [1:0] t;
    input  [1:0] r;
    output [2:0] x0; output [2:0] y0;
    output [2:0] x1; output [2:0] y1;
    output [2:0] x2; output [2:0] y2;
    output [2:0] x3; output [2:0] y3;
    begin
        case ({t, r})
        // I
        4'b00_00: begin x0=0;y0=0; x1=1;y1=0; x2=2;y2=0; x3=3;y3=0; end
        4'b00_01: begin x0=0;y0=0; x1=0;y1=1; x2=0;y2=2; x3=0;y3=3; end
        4'b00_10: begin x0=0;y0=0; x1=1;y1=0; x2=2;y2=0; x3=3;y3=0; end
        4'b00_11: begin x0=0;y0=0; x1=0;y1=1; x2=0;y2=2; x3=0;y3=3; end
        // O
        4'b01_00,4'b01_01,4'b01_10,4'b01_11:
                  begin x0=0;y0=0; x1=1;y1=0; x2=0;y2=1; x3=1;y3=1; end
        // T
        4'b10_00: begin x0=0;y0=0; x1=1;y1=0; x2=2;y2=0; x3=1;y3=1; end
        4'b10_01: begin x0=0;y0=0; x1=0;y1=1; x2=1;y2=1; x3=0;y3=2; end
        4'b10_10: begin x0=1;y0=0; x1=0;y1=1; x2=1;y2=1; x3=2;y3=1; end
        4'b10_11: begin x0=1;y0=0; x1=0;y1=1; x2=1;y2=1; x3=1;y3=2; end
        // S
        4'b11_00: begin x0=1;y0=0; x1=2;y1=0; x2=0;y2=1; x3=1;y3=1; end
        4'b11_01: begin x0=0;y0=0; x1=0;y1=1; x2=1;y2=1; x3=1;y3=2; end
        4'b11_10: begin x0=1;y0=0; x1=2;y1=0; x2=0;y2=1; x3=1;y3=1; end
        4'b11_11: begin x0=0;y0=0; x1=0;y1=1; x2=1;y2=1; x3=1;y3=2; end
        default:  begin x0=0;y0=0; x1=1;y1=0; x2=0;y2=1; x3=1;y3=1; end
        endcase
    end
endtask
//rtos 구현... system .... 
//------------------------------------------------------------
// 현재 셀 좌표 (combinational)
//------------------------------------------------------------
wire [2:0] rx0,ry0, rx1,ry1, rx2,ry2, rx3,ry3;

// task를 wire에 연결하기 위해 always+reg로 래핑
reg [2:0] _rx0,_ry0,_rx1,_ry1,_rx2,_ry2,_rx3,_ry3;
always @(*) get_cells(block_type, rotation,
    _rx0,_ry0, _rx1,_ry1, _rx2,_ry2, _rx3,_ry3);

assign cell_x0 = block_x + _rx0; assign cell_y0 = block_y - _ry0;
assign cell_x1 = block_x + _rx1; assign cell_y1 = block_y - _ry1;
assign cell_x2 = block_x + _rx2; assign cell_y2 = block_y - _ry2;
assign cell_x3 = block_x + _rx3; assign cell_y3 = block_y - _ry3;

//------------------------------------------------------------
// 충돌 감지 (완전 combinational)
// 다음 위치(nx, ny)와 다음 rotation(nrot)으로 즉시 계산
//------------------------------------------------------------
// 낙하 충돌 (block_y-1, 현재 rotation)
reg [2:0] d_rx0,d_ry0,d_rx1,d_ry1,d_rx2,d_ry2,d_rx3,d_ry3;
always @(*) get_cells(block_type, rotation,
    d_rx0,d_ry0, d_rx1,d_ry1, d_rx2,d_ry2, d_rx3,d_ry3);

wire [5:0] dy0 = block_y - 1 - d_ry0;
wire [5:0] dy1 = block_y - 1 - d_ry1;
wire [5:0] dy2 = block_y - 1 - d_ry2;
wire [5:0] dy3 = block_y - 1 - d_ry3;

wire [3:0] dx0 = block_x + d_rx0;
wire [3:0] dx1 = block_x + d_rx1;
wire [3:0] dx2 = block_x + d_rx2;
wire [3:0] dx3 = block_x + d_rx3;

// 바닥(y==0) 또는 맵에 이미 블록
wire drop_col =
    (dy0 >= `TETRIS_H || tetris_map[dy0][dx0]) ||
    (dy1 >= `TETRIS_H || tetris_map[dy1][dx1]) ||
    (dy2 >= `TETRIS_H || tetris_map[dy2][dx2]) ||
    (dy3 >= `TETRIS_H || tetris_map[dy3][dx3]);

// 왼쪽 충돌 (block_x-1)
reg [2:0] l_rx0,l_ry0,l_rx1,l_ry1,l_rx2,l_ry2,l_rx3,l_ry3;
always @(*) get_cells(block_type, rotation,
    l_rx0,l_ry0, l_rx1,l_ry1, l_rx2,l_ry2, l_rx3,l_ry3);

wire signed [4:0] lx0 = block_x - 1 + l_rx0;
wire signed [4:0] lx1 = block_x - 1 + l_rx1;
wire signed [4:0] lx2 = block_x - 1 + l_rx2;
wire signed [4:0] lx3 = block_x - 1 + l_rx3;

wire [5:0] ly0 = block_y - l_ry0;
wire [5:0] ly1 = block_y - l_ry1;
wire [5:0] ly2 = block_y - l_ry2;
wire [5:0] ly3 = block_y - l_ry3;

wire left_col =
    (lx0 < 0 || tetris_map[ly0][lx0]) ||
    (lx1 < 0 || tetris_map[ly1][lx1]) ||
    (lx2 < 0 || tetris_map[ly2][lx2]) ||
    (lx3 < 0 || tetris_map[ly3][lx3]);

// 오른쪽 충돌 (block_x+1)
reg [2:0] ri_rx0,ri_ry0,ri_rx1,ri_ry1,ri_rx2,ri_ry2,ri_rx3,ri_ry3;
always @(*) get_cells(block_type, rotation,
    ri_rx0,ri_ry0, ri_rx1,ri_ry1, ri_rx2,ri_ry2, ri_rx3,ri_ry3);

wire [4:0] rx_0 = block_x + 1 + ri_rx0;
wire [4:0] rx_1 = block_x + 1 + ri_rx1;
wire [4:0] rx_2 = block_x + 1 + ri_rx2;
wire [4:0] rx_3 = block_x + 1 + ri_rx3;

wire [5:0] ry_0 = block_y - ri_ry0;
wire [5:0] ry_1 = block_y - ri_ry1;
wire [5:0] ry_2 = block_y - ri_ry2;
wire [5:0] ry_3 = block_y - ri_ry3;

wire right_col =
    (rx_0 >= `TETRIS_W || tetris_map[ry_0][rx_0]) ||
    (rx_1 >= `TETRIS_W || tetris_map[ry_1][rx_1]) ||
    (rx_2 >= `TETRIS_W || tetris_map[ry_2][rx_2]) ||
    (rx_3 >= `TETRIS_W || tetris_map[ry_3][rx_3]);

// 회전 충돌 (rotation+1)
reg [2:0] ro_rx0,ro_ry0,ro_rx1,ro_ry1,ro_rx2,ro_ry2,ro_rx3,ro_ry3;
always @(*) get_cells(block_type, rotation + 1,
    ro_rx0,ro_ry0, ro_rx1,ro_ry1, ro_rx2,ro_ry2, ro_rx3,ro_ry3);

wire [4:0] rox0 = block_x + ro_rx0; wire [5:0] roy0 = block_y - ro_ry0;
wire [4:0] rox1 = block_x + ro_rx1; wire [5:0] roy1 = block_y - ro_ry1;
wire [4:0] rox2 = block_x + ro_rx2; wire [5:0] roy2 = block_y - ro_ry2;
wire [4:0] rox3 = block_x + ro_rx3; wire [5:0] roy3 = block_y - ro_ry3;

wire rot_col =
    (rox0 >= `TETRIS_W || roy0 >= `TETRIS_H || tetris_map[roy0][rox0]) ||
    (rox1 >= `TETRIS_W || roy1 >= `TETRIS_H || tetris_map[roy1][rox1]) ||
    (rox2 >= `TETRIS_W || roy2 >= `TETRIS_H || tetris_map[roy2][rox2]) ||
    (rox3 >= `TETRIS_W || roy3 >= `TETRIS_H || tetris_map[roy3][rox3]);

//------------------------------------------------------------
// DROP CLOCK
//------------------------------------------------------------
reg [25:0] drop_counter;
reg        drop_clk;
reg [1:0] speed_level;
wire [25:0] drop_limit =
    (speed_level == 2'd0) ? 26'd33000000 :
    (speed_level == 2'd1) ? 26'd16500000 :
    (speed_level == 2'd2) ? 26'd8250000 :
                            26'd3300000;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        drop_counter <= 0;
        drop_clk     <= 0;
    end
    else begin
        drop_counter <= drop_counter + 1;
        if (drop_counter == drop_limit) begin
            drop_counter <= 0;
            drop_clk     <= 1;
        end
        else
            drop_clk <= 0;
    end
end

//------------------------------------------------------------
// BUTTON EDGE DETECT
//------------------------------------------------------------
reg key_left_d, key_right_d, key_rot_d, key_speed_d;
wire key_left_pulse  = (~key_in[1]) & key_left_d;
wire key_right_pulse = (~key_in[3]) & key_right_d;
wire key_rot_pulse   = (~key_in[0]) & key_rot_d;
wire key_speed_pulse = (~key_in[2]) & key_speed_d;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        key_left_d  <= 1'b1;
        key_right_d <= 1'b1;
        key_rot_d   <= 1'b1;
        key_speed_d <= 1'b1;
        speed_level <= 2'b0;
    end
    else begin
        key_left_d       <= key_in[1];
        key_right_d      <= key_in[3];
        key_rot_d        <= key_in[0];
        key_speed_d      <= key_in[2];
        if (key_speed_pulse)
           speed_level <= speed_level+1;
        
    end
end

//------------------------------------------------------------
// GAME FSM
//------------------------------------------------------------
integer i;

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        block_x    <= 4;
        block_y    <= 20;
        block_type <= 0;
        rotation   <= 0;
        state      <= STATE_SPAWN;
        clear_row  <= 0;
        score      <= 0;
        for (i = 0; i < `TETRIS_H; i = i + 1)
            tetris_map[i] <= 10'b0;
    end

    else begin

        case (state)

        //----------------------------------------------------
        STATE_SPAWN: begin
            block_x    <= 4;
            block_y    <= 20;
            block_type <= next_type;
            rotation   <= 0;
            state      <= STATE_FALL;
        end

        //----------------------------------------------------
        STATE_FALL: begin

            if (key_left_pulse && !left_col)
                block_x <= block_x - 1;

            if (key_right_pulse && !right_col)
                block_x <= block_x + 1;

            if (key_rot_pulse && !rot_col)
                rotation <= rotation + 1;
                
            if (drop_clk) begin
                if (!drop_col)
                    block_y <= block_y - 1;
                else
                    state <= STATE_MERGE;
            end

        end

        //----------------------------------------------------
        STATE_MERGE: begin
            tetris_map[cell_y0][cell_x0] <= 1'b1;
            tetris_map[cell_y1][cell_x1] <= 1'b1;
            tetris_map[cell_y2][cell_x2] <= 1'b1;
            tetris_map[cell_y3][cell_x3] <= 1'b1;
            clear_row <= 0;
            state     <= STATE_CLEAR;
        end

        //----------------------------------------------------
        STATE_CLEAR: begin
            if (clear_row >= `TETRIS_H) begin
                state <= STATE_SPAWN;
            end
            else if (tetris_map[clear_row] == 10'b1111111111) begin
                for (i = 0; i < `TETRIS_H - 1; i = i + 1)
                    if (i >= clear_row)
                        tetris_map[i] <= tetris_map[i + 1];
                tetris_map[`TETRIS_H - 1] <= 10'b0;
                
                if(score <= 16'd9900)
                    score<=score+16'd100;
                clear_row <= clear_row + 1;
            end
            else begin
                clear_row <= clear_row + 1;
            end
        end

        endcase

    end

end

endmodule