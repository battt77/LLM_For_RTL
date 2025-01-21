module RegisterFile #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire [ADDR_WIDTH-1:0] ra0, ra1,
    output wire [DATA_WIDTH-1:0] rd0, rd1,
    input wire [DATA_WIDTH-1:0] wd,
    input wire [ADDR_WIDTH-1:0] wa,
    input wire wen,
    output wire a0zero
);

    // Register file array
    reg [DATA_WIDTH-1:0] rf [0:2**ADDR_WIDTH-1];

    // Read operations
    assign rd0 = rf[ra0];
    assign rd1 = rf[ra1];

    // Output a0zero if the register at address 10 is zero
    assign a0zero = ~|rf[10];

    // Write operation
    always @(posedge clk) begin
        if (wen && wa != 0) begin
            rf[wa] <= wd;
        end
    end

endmodule