module lcd #(
	parameter ACTIVE_HORIZONTAL = 480, // pixels
	parameter BUFFER_HORIZONTAL = 45, //clocks
	parameter ACTIVE_VERTICAL = 272, //lines
	parameter BUFFER_VERTICAL = 13,// LINES
	parameter SPRITE_WIDTH = 16,
	parameter SPRITE_HEIGHT = 16,
	parameter HORIZ_PADDING = 2,
	parameter VERTICAL_PADDING = 2
)(
    input  rst,
    input  pclk,        // should get 8MHz clk
    input [15:0] pixel,

    output LCD_DE,      // Display Enable
    output [7:0] pixel_address,
    output [4:0] LCD_B, // 5-bit blue color data
    output [5:0] LCD_G, // 6-bit green color data
    output [4:0] LCD_R  // 5-bit red color data
);

localparam HORIZONTAL_TOTAL = ACTIVE_HORIZONTAL + BUFFER_HORIZONTAL;
localparam VERTICAL_TOTAL = ACTIVE_VERTICAL + BUFFER_VERTICAL;

//Lab Specific
localparam HORIZ_ITERATIONS = ACTIVE_HORIZONTAL / (SPRITE_WIDTH + HORIZONTAL_PADDING);
localparam VERTICAL_ITERATIONS = ACTIVE_VERTICAL / (SPRITE_HEIGHT + VERTICAL_PADDING);

logic [$clog2(HORIZONTAL_TOTAL)-1:0] horizontal_pos;
logic [$clog2(VERTICAL_TOTAL)-1:0] vertical_pos;

//Track Positions
always_ff @(posedge pclk) begin
	if (horizontal_pos >= HORIZONTAL_TOTAL - 1) begin
		horizontal_pos <= 0;
		if (vertical_pos >= VERTICAL_TOTAL - 1)
			vertical_pos <= 0;
		else
			vertical_pos <= 1 + vertical_pos;
	end
	else horizontal_pos <= 1 + horizontal_pos;
end


//When and what to output
always_comb begin : blockName
	LCD_DE = 0;
	LCD_R  = 0;
	LCD_B  = 0;
	LCD_G  = 0;

	if (horizontal_pos < ACTIVE_HORIZONTAL &&
		vertical_pos   < ACTIVE_VERTICAL ) begin
			//Active Display Write Zone
			LCD_DE = 1'b1;


	end
	// If not in active zone, do nothing
end


endmodule
