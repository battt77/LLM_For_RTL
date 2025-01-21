module imm(
    input [31:7] immin,
    input [2:0] ExtOP,
    output [31:0] immout
);
    // Define extended immediate values for each type
    wire [31:0] immI = {{20{immin[31]}}, immin[31:20]};
    wire [31:0] immU = {immin[31:12], 12'b0};
    wire [31:0] immS = {{20{immin[31]}}, immin[31:25], immin[11:7]};
    wire [31:0] immB = {{20{immin[31]}}, immin[7], immin[30:25], immin[11:8], 1'b0};
    wire [31:0] immJ = {{12{immin[31]}}, immin[19:12], immin[20], immin[30:21], 1'b0};
    
    // Instantiate MuxKeyWithDefault
    MuxKeyWithDefault #(5, 3, 32) immtype (
        immout, // Output
        ExtOP,  // Selection signal
        32'b0,  // Default output
        {       // Lookup table
            3'b000, immI,
            3'b001, immU,
            3'b010, immS,
            3'b011, immB,
            3'b100, immJ
        }
    );
endmodule