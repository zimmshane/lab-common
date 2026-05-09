module spi #(
    parameter LENGTH = 4
)(
    input spi_clk,
    input poci,
    input pico,
    input cs,
    output logic [LENGTH-1:0] data
);

always @(posedge spi_clk) begin
    if (!cs) begin
        data <= {data[LENGTH-2:0],pico};
    end
end 


endmodule