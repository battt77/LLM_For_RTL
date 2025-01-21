module RegisterFile #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] ra0,
    input wire [ADDR_WIDTH-1:0] ra1,
    input wire [DATA_WIDTH-1:0] wd,
    input wire [ADDR_WIDTH-1:0] wa,
    input wire wen,
    output wire [DATA_WIDTH-1:0] rd0,
    output wire [DATA_WIDTH-1:0] rd1,
    output wire a0zero
);

    // Calculate the number of registers
    localparam NUM_REGS = 1 << ADDR_WIDTH;
    
    // Register array
    reg [DATA_WIDTH-1:0] regfile [0:NUM_REGS-1];
    
    // Read operations (combinational)
    assign rd0 = regfile[ra0];
    assign rd1 = regfile[ra1];
    
    // Check if register at address 10 is zero
    assign a0zero = ~|regfile[10];
    
    // Write operation (synchronous)
    always @(posedge clk) begin
        if (wen && wa != 0) begin
            regfile[wa] <= wd;
        end
    end

endmodule