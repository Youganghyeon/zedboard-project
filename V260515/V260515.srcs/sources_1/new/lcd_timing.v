`timescale 1ns / 1ps

module lcd_timing (
    input  wire        clk,
    input  wire        rst_n,

    output wire        data_valid,
    output wire        data_req,
    output wire [10:0] pix_x,
    output wire [10:0] pix_y,

    output wire        hsync,
    output wire        vsync
);

parameter H_BLANK = 46;
parameter H_DISP  = 800;
parameter H_TOTAL = 1056;

parameter V_BLANK = 23;
parameter V_DISP  = 480;
parameter V_TOTAL = 525;

reg [11:0] cnt_h;
reg [9:0]  cnt_v;

always @(posedge clk or negedge rst_n) begin

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

assign pix_x = data_req ? (cnt_h - (H_BLANK - 1)) : 0;
assign pix_y = data_req ? (cnt_v - V_BLANK)        : 0;

assign hsync = (cnt_h <= H_BLANK - 1);
assign vsync = (cnt_v <= V_BLANK - 1);

endmodule