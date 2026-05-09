module lcd #(
	parameter ACTIVE_HORIZONTAL = 480, // pixels
	parameter BUFFER_HORIZONTAL = 45, //clocks
	parameter ACTIVE_VERTICAL = 272, //lines
	parameter BUFFER_VERTICAL = 13,// LINES
	parameter SPRITE_WIDTH = 16,
	parameter SPRITE_HEIGHT = 16,
	parameter PADDING_ELEMENT = 16'h00F0,
	parameter HORIZONTAL_PADDING = 10,
	parameter VERTICAL_PADDING = 10
)(
    input  rst,
    input  pclk,        // 8MHz clk
    input [15:0] pixel,

    output logic LCD_DE,      // Display Enable
    output logic [7:0] pixel_address,
    output logic [4:0] LCD_B, // 5-bit blue color data
    output logic [5:0] LCD_G, // 6-bit green color data
    output logic [4:0] LCD_R  // 5-bit red color data
);

localparam HORIZONTAL_TOTAL = ACTIVE_HORIZONTAL + BUFFER_HORIZONTAL;
localparam VERTICAL_TOTAL = ACTIVE_VERTICAL + BUFFER_VERTICAL;

localparam HORIZ_CYCLE = SPRITE_WIDTH + HORIZONTAL_PADDING;
localparam VERT_CYCLE  = SPRITE_HEIGHT + VERTICAL_PADDING;

// Absolute LCD scan position
logic [$clog2(HORIZONTAL_TOTAL)-1:0] horizontal_pos;
logic [$clog2(VERTICAL_TOTAL)-1:0]   vertical_pos;

// Sprite + Padding  position within the repeating tiles
logic [$clog2(HORIZ_CYCLE)-1:0] h_cycle_pos;
logic [$clog2(VERT_CYCLE)-1:0]  v_cycle_pos;

// Derived signals for output logic
logic in_sprite_h;
logic in_sprite_v;
logic [$clog2(SPRITE_WIDTH)-1:0]  sprite_col;
logic [$clog2(SPRITE_HEIGHT)-1:0] sprite_row;


// Position tracking
always_ff @(posedge pclk) begin
	if (horizontal_pos >= HORIZONTAL_TOTAL - 1) begin
	    // End of scanline
		horizontal_pos <= 0;
		h_cycle_pos    <= 0;

		if (vertical_pos >= VERTICAL_TOTAL - 1) begin
		    // End of frame
			vertical_pos <= 0;
			v_cycle_pos  <= 0;
		end else begin
			vertical_pos <= vertical_pos + 1;
			if (v_cycle_pos >= VERT_CYCLE - 1)
				v_cycle_pos <= 0;
			else
				v_cycle_pos <= v_cycle_pos + 1;
		end
	end else begin
	    // In scanline
		horizontal_pos <= horizontal_pos + 1;
		if (h_cycle_pos >= HORIZ_CYCLE - 1)
			h_cycle_pos <= 0;
		else
			h_cycle_pos <= h_cycle_pos + 1;
	end
end


// Pixel address & LCD output
always_comb begin
	// Defaults
	pixel_address = 8'd0;
	LCD_DE = 1'b0;
	LCD_R  = 5'd0;
	LCD_G  = 6'd0;
	LCD_B  = 5'd0;

	// Determine whether we are inside the sprite portion of the tile
	in_sprite_h = (h_cycle_pos < SPRITE_WIDTH);
	in_sprite_v = (v_cycle_pos < SPRITE_HEIGHT);

	// Coordinates inside the sprite itself
	sprite_col = h_cycle_pos[$clog2(SPRITE_WIDTH)-1:0];
	sprite_row = v_cycle_pos[$clog2(SPRITE_HEIGHT)-1:0];

	if (horizontal_pos < ACTIVE_HORIZONTAL &&
		vertical_pos   < ACTIVE_VERTICAL ) begin
		LCD_DE = 1'b1;
		if (in_sprite_h && in_sprite_v) begin
		    // Inside a sprite tile
			LCD_R  = pixel[15:11];
			LCD_B  = pixel[4:0];
			LCD_G  = pixel[10:5];

			// Normal row-major addressing:
			// pixel_address = sprite_col + sprite_row * SPRITE_WIDTH;
			// 90 deg CCW rotation:
			pixel_address = sprite_col * SPRITE_HEIGHT + (SPRITE_WIDTH - 1 - sprite_row);
		end else begin
		    // In a padding zone (horizontal gap, vertical gap, or both)
			LCD_R = PADDING_ELEMENT[15:11];
			LCD_B = PADDING_ELEMENT[4:0];
			LCD_G = PADDING_ELEMENT[10:5];
		end
	end
	// Outside active area: keep outputs at default (blank)
end

endmodule
