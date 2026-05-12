`include "clk_divider.sv"
`include "spi_receiver.sv"
`include "lcd.sv"
`include "sprite_buf_Ex2.sv"

module top (
    input  CLK,
    input  cs,
    input  spi_clk,
    input  pico,
    output reg        LCD_CLK,
    output            LCD_DEN,
    output [4:0]      LCD_R,
    output [5:0]      LCD_G,
    output [4:0]      LCD_B
);

    // LCD pixel clock - only used only as output pin
    logic lcd_clk_int;

    clk_divider #(.CLK_OUT_FREQ(8_000_000)) clk_div (
        .clk(CLK), .slow_clk(lcd_clk_int)
    );

    // 1 cycle delay to lcd_tick
    logic lcd_clk_prev;
    always_ff @(posedge CLK) begin
        LCD_CLK      <= lcd_clk_int;
        lcd_clk_prev <= lcd_clk_int;
    end
    wire lcd_tick = lcd_clk_int && !lcd_clk_prev;

    //SPI
    logic        spi_we;
    logic [7:0]  spi_waddr;
    logic [15:0] spi_wdata;

    spi_receiver spi_rx (
        .clk(CLK),
        .spi_clk_pin(spi_clk),
        .mosi_pin(pico),
        .cs_pin(cs),
        .we(spi_we),
        .waddr(spi_waddr),
        .wdata(spi_wdata)
    );

    logic [7:0]  pixel_address;
    logic [15:0] pixel_data;

    dp_buffer sprite_buf (
        .clk(CLK),
        .we(spi_we),     .waddr(spi_waddr), .wdata(spi_wdata),
        .raddr(pixel_address), .rdata(pixel_data)
    );

    lcd lcd_inst (
        .clk(CLK),       .tick(lcd_tick),
        .pixel(pixel_data),
        .pixel_address(pixel_address),
        .LCD_DE(LCD_DEN), .LCD_R(LCD_R), .LCD_G(LCD_G), .LCD_B(LCD_B)
    );

endmodule
