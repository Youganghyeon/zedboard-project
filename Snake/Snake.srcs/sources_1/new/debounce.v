`timescale 1ns / 1ps

module top(
    input CLK100MHZ, // 100MHz??
    input reset, // ñìãæ?ã·
    input up,right,down,left, // Û°ú¾?
    input pause, // ?ïÎ
    input slow_down, // ?áÜ
    output [7:0] an, // ??Î·ÞÅÒö
    output [7:0] seg, // ??Î·?õó
    output [11:0] vga, // vga?ãÆ?õó£¬?ßí?R,G,BÊÀ4êÈ
    output h_sync,v_sync // ú¼¡¢Öª?ÙÚãá?
 	
 	
// 	// FOR DEBUG
// 	output [11:0] led
// 	output display_hit_wall,
// 	output display_hit_itself,
// 	output display_get_apple,
// 	output display_is_launching
    );
    
    

    
    wire CLK148DOT5MHZ; // 148.5Mhz??
	
	// éÄéÍÙ¼????ì£??? [5:0] snake_x/y [31:0]
	// ?ÍÅí» https://stackoverflow.com/questions/16369698/how-to-pass-array-structure-between-two-verilog-modules
    wire [32*6-1:0] snake_x_temp; // Þïãóñ¦????Õá
    wire [32*6-1:0] snake_y_temp; // Þïãóñ¦????Õá
    
	wire [31:0] snake_piece_is_display;  // Íóð¤??
	
	wire [5:0] apple_x; // ?Íýñ¦?
	wire [5:0] apple_y; // ?Íýñ¦?
	
	// êý??? 00: LAUNCHING  01: PLAYING   10:DIE_FLASHING   11: INITIALIZING
	wire [1:0] game_status; 
	
	// Û°ú¾ 00: UP   01: Right   10: DOWN   11: LEFT
	wire [1:0] current_direction;
	wire [1:0] next_direction;
	
	
	
	wire get_apple; // ýÞÓð?Íý
	
	wire hit_wall; // ÓÕ?Üú
	wire hit_itself; // ÓÕÐùÜú
	

    clk_wiz_0 (CLK148DOT5MHZ,CLK100MHZ);
    
    display (
        .clock(CLK148DOT5MHZ), // ð¶Öõvga£¬Ðì?Ô´ãÀ100MHZîÜclock
        .h_sync(h_sync),
        .v_sync(v_sync),
        .vga(vga),
        .game_status(game_status),
        .apple_x(apple_x),
        .apple_y(apple_y),
        .snake_x_temp(snake_x_temp),
        .snake_y_temp(snake_y_temp),
        .snake_piece_is_display(snake_piece_is_display)
        );
    
    snake (
    	.clock(CLK100MHZ),
    	.pause(pause),
    	.slow_down(slow_down),
    	.snake_x_temp(snake_x_temp),
    	.snake_y_temp(snake_y_temp),
    	.apple_x(apple_x),
    	.apple_y(apple_y),
    	.snake_piece_is_display(snake_piece_is_display),
    	.get_apple(get_apple),
    	.game_status(game_status),
        .current_direction(current_direction),
    	.next_direction(next_direction),
    	.hit_wall(hit_wall),
    	.hit_itself(hit_itself)
    	);
     
    fsm (
        .reset(reset),
        .clock(CLK100MHZ),
        .game_status(game_status),
        .hit_wall(hit_wall),
        .hit_itself(hit_itself),
    	.up(up),
        .right(right),
        .down(down),
        .left(left)
        );
    
    turn (
    	.clock(CLK100MHZ),
    	.up(up),
    	.right(right),
    	.down(down),
    	.left(left),
    	.current_direction(current_direction),
    	.next_direction(next_direction)
    	);
     
    apple (
        .clock(CLK100MHZ),
        .apple_x(apple_x),
        .apple_y(apple_y),
        .get_apple(get_apple),
        .game_status(game_status)
        );
        
    score (
    	.reset(reset),
    	.clock(CLK100MHZ),
    	.get_apple(get_apple),
		.game_status(game_status),
    	.an(an),
    	.seg(seg)
        );
     
//    // FOR DEBUG
//	assign led[11:6]=apple_x;
//	assign led[5:0]=apple_y;
//	assign display_hit_wall=hit_wall;
//	assign display_hit_itself=hit_itself;
//	assign display_get_apple=get_apple;
//	assign display_is_launching=(game_status==2'b00);
	

endmodule