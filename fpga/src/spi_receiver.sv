module spi_receiver (
    input  logic clk,           // system clock (25 MHz)

    // Raw SPI pins (directly from FPGA pads)
    input  logic spi_clk_pin,
    input  logic mosi_pin,
    input  logic cs_pin,

    // Decoded output
    output logic        we,
    output logic [7:0]  waddr,
    output logic [15:0] wdata
);

    // 2-stage synchronizers
    logic sck_s1, sck_s2, sck_prev;
    logic cs_s1,  cs_s2,  cs_prev;
    logic mosi_s1, mosi_s2;

    always_ff @(posedge clk) begin
        sck_s1   <= spi_clk_pin;
        sck_s2   <= sck_s1;
        sck_prev <= sck_s2;

        cs_s1   <= cs_pin;
        cs_s2   <= cs_s1;
        cs_prev <= cs_s2;

        mosi_s1 <= mosi_pin;
        mosi_s2 <= mosi_s1;
    end

    wire sck_rising = sck_s2 && !sck_prev;
    wire cs_rising  = cs_s2  && !cs_prev;

    logic [23:0] shift_reg;

    always_ff @(posedge clk) begin
        if (sck_rising)
            shift_reg <= {shift_reg[22:0], mosi_s2};
    end

    // Capture on CS rising edge (transfer complete)
    logic [23:0] captured;

    always_ff @(posedge clk) begin
        we <= 1'b0;
        if (cs_rising) begin
            captured <= shift_reg;
            we       <= 1'b1;
        end
    end

    // Protocol decode: {addr, pixel_LSB, pixel_MSB} → byte-swap pixel
    assign waddr = captured[23:16];
    assign wdata = {captured[7:0], captured[15:8]};

endmodule
