`timescale 1ns / 1ps

module game_logic (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [3:0]  key_in,

    output reg  [3:0]  block_x,
    output reg  [5:0]  block_y,

    // tetris_map을 외부(renderer)에서 읽을 수 있도록 포트 제공
    // h_div, w_div 입력받아 해당 칸이 채워졌는지 출력
    input  wire [5:0]  rd_h,
    input  wire [3:0]  rd_w,
    output wire        map_bit
);

`define TETRIS_W  10
`define TETRIS_H  22

//------------------------------------------------------------
// FSM
//------------------------------------------------------------
localparam STATE_SPAWN = 2'd0;
localparam STATE_FALL  = 2'd1;
localparam STATE_MERGE = 2'd2;

reg [1:0] state;

//------------------------------------------------------------
// MAP
//------------------------------------------------------------
reg [9:0] tetris_map [0:`TETRIS_H-1];

assign map_bit = tetris_map[rd_h][rd_w];

//------------------------------------------------------------
// DROP CLOCK
//------------------------------------------------------------
reg [25:0] drop_counter;
reg        drop_clk;

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        drop_counter <= 0;
        drop_clk     <= 0;
    end

    else begin

        drop_counter <= drop_counter + 1;

        if (drop_counter == 26'd33000000) begin
            drop_counter <= 0;
            drop_clk     <= 1;
        end

        else begin
            drop_clk <= 0;
        end

    end

end

//------------------------------------------------------------
// BUTTON EDGE DETECT
//------------------------------------------------------------
reg key_left_d;
reg key_right_d;

wire key_left_pulse;
wire key_right_pulse;

assign key_left_pulse  = (~key_in[1]) & key_left_d;
assign key_right_pulse = (~key_in[3]) & key_right_d;

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        key_left_d  <= 1'b1;
        key_right_d <= 1'b1;
    end

    else begin
        key_left_d  <= key_in[1];
        key_right_d <= key_in[3];
    end

end

//------------------------------------------------------------
// GAME FSM
//------------------------------------------------------------
integer i;

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        block_x <= 4;
        block_y <= 20;
        state   <= STATE_SPAWN;

        for (i = 0; i < `TETRIS_H; i = i + 1)
            tetris_map[i] <= 10'b0000000000;

    end

    else begin

        case (state)

        //----------------------------------------------------
        STATE_SPAWN: begin
            block_x <= 4;
            block_y <= 20;
            state   <= STATE_FALL;
        end

        //----------------------------------------------------
        STATE_FALL: begin

            if (key_left_pulse)
                if (block_x > 0)
                    block_x <= block_x - 1;

            if (key_right_pulse)
                if (block_x < (`TETRIS_W - 2))
                    block_x <= block_x + 1;

            if (drop_clk) begin

                if (
                    (block_y > 1) &&
                    !tetris_map[block_y - 2][block_x] &&
                    !tetris_map[block_y - 2][block_x + 1]
                )
                    block_y <= block_y - 1;

                else
                    state <= STATE_MERGE;

            end

        end

        //----------------------------------------------------
        STATE_MERGE: begin

            tetris_map[block_y    ][block_x    ] <= 1'b1;
            tetris_map[block_y    ][block_x + 1] <= 1'b1;
            tetris_map[block_y - 1][block_x    ] <= 1'b1;
            tetris_map[block_y - 1][block_x + 1] <= 1'b1;

            state <= STATE_SPAWN;

        end

        endcase

    end

end

endmodule