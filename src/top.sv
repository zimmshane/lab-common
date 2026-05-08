`include "clk_divider.sv"
`include "lcd.sv"

module top
(
    input CLK, //FPGA's cock

	output LCD_CLK,//LCD clock. 
	output LCD_DEN,
	output [4:0] LCD_R,
	output [5:0] LCD_G,
	output [4:0] LCD_B
);

clk_divider #(.CLK_OUT_FREQ(8_000_000)) clk_div
(
    .clk(CLK),
    .slow_clk(LCD_CLK)
);

lcd lcd
(
	.rst(1'b0),
	.pclk(LCD_CLK),
	.LCD_R(LCD_R),
	.LCD_B(LCD_B),
	.LCD_G(LCD_G),
	.LCD_DE(LCD_DEN)
);
endmodule