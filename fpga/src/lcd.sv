module lcd #(
    parameter ACTIVE_HORIZONTAL = 480,
    parameter BUFFER_HORIZONTAL = 45,
    parameter ACTIVE_VERTICAL   = 272,
    parameter BUFFER_VERTICAL   = 13,
    parameter SPRITE_WIDTH      = 16,
    parameter SPRITE_HEIGHT     = 16,
    parameter PADDING_ELEMENT   = 16'h0000,
    parameter HORIZONTAL_PADDING = 1,
    parameter VERTICAL_PADDING   = 1
)(
    input  clk,             // 25 MHz system clock
    input  tick,            // clock enable — one pulse per LCD pixel clock
    input  [15:0] pixel,

    output logic       LCD_DE,
    output logic [7:0] pixel_address,
    output logic [4:0] LCD_B,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_R
);

    localparam H_TOTAL     = ACTIVE_HORIZONTAL + BUFFER_HORIZONTAL;
    localparam V_TOTAL     = ACTIVE_VERTICAL   + BUFFER_VERTICAL;
    localparam HORIZ_CYCLE = SPRITE_WIDTH  + HORIZONTAL_PADDING;
    localparam VERT_CYCLE  = SPRITE_HEIGHT + VERTICAL_PADDING;

    // Scan position
    logic [$clog2(H_TOTAL)-1:0]     h_pos;
    logic [$clog2(V_TOTAL)-1:0]     v_pos;
    logic [$clog2(HORIZ_CYCLE)-1:0] h_tile;
    logic [$clog2(VERT_CYCLE)-1:0]  v_tile;


    logic in_sprite_h_d, in_sprite_v_d, active_d;

    // track scan position
    always_ff @(posedge clk) begin
        if (tick) begin
            if (h_pos >= H_TOTAL - 1) begin
                h_pos  <= 0;
                h_tile <= 0;
                if (v_pos >= V_TOTAL - 1) begin
                    v_pos  <= 0;
                    v_tile <= 0;
                end else begin
                    v_pos  <= v_pos + 1;
                    v_tile <= (v_tile >= VERT_CYCLE - 1) ? '0 : v_tile + 1;
                end
            end else begin
                h_pos  <= h_pos + 1;
                h_tile <= (h_tile >= HORIZ_CYCLE - 1) ? '0 : h_tile + 1;
            end
        end
    end

    wire in_sprite_h = (h_tile < SPRITE_WIDTH);
    wire in_sprite_v = (v_tile < SPRITE_HEIGHT);

    // Compute pixel address (delayed)
        if (in_sprite_h && in_sprite_v)
            pixel_address = v_tile[$clog2(SPRITE_HEIGHT)-1:0] * SPRITE_WIDTH
                          + h_tile[$clog2(SPRITE_WIDTH)-1:0];
        else
            pixel_address = 8'd0;
    end

    // add one cycle delay to align with BRAM read latency
    always_ff @(posedge clk) begin
        in_sprite_h_d <= in_sprite_h;
        in_sprite_v_d <= in_sprite_v;
        active_d      <= (h_pos < ACTIVE_HORIZONTAL) && (v_pos < ACTIVE_VERTICAL);
    end

    // drive LCD pins
    always_comb begin
        LCD_DE = 1'b0;
        LCD_R = 1'b0;
        LCD_G = 1'b0;
        LCD_B = 1'b0;

        if (active_d) begin
            LCD_DE = 1'b1;
            if (in_sprite_h_d && in_sprite_v_d) begin
                LCD_R = pixel[15:11];
                LCD_G = pixel[10:5];
                LCD_B = pixel[4:0];
            end
            else begin
                LCD_R = PADDING_ELEMENT[15:11];
                LCD_G = PADDING_ELEMENT[10:5];
                LCD_B = PADDING_ELEMENT[4:0]};
            end
        end
    end

endmodule
