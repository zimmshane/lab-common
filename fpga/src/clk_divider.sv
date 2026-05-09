module clk_divider #(
    parameter CLK_IN_FREQ  = 25_000_000,  // Hz
    parameter CLK_OUT_FREQ = 10           // Hz
) (
    input  logic clk,
    output logic slow_clk = 1'b0
);

localparam DIVIDE_FACTOR = CLK_IN_FREQ / (CLK_OUT_FREQ * 2);

reg [$clog2(DIVIDE_FACTOR)-1:0] counter = 0;

always @(posedge clk) begin
    if (counter >= DIVIDE_FACTOR - 1) begin
        slow_clk <= ~slow_clk;
        counter  <= 0;
    end else begin
        counter <= counter + 1;
    end
end

endmodule