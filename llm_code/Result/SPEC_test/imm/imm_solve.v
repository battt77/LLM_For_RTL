module imm (
    input [24:0] immin,  // 25-bit input (bits [31:7] of the instruction)
    input [2:0] ExtOP,   // 3-bit control signal to select the immediate type
    output [31:0] immout // 32-bit output for the generated immediate value
);

    // Generate the I-type immediate
    wire [31:0] immI = {{20{immin[24]}}, immin[24:13]}; // Sign-extend bits [24:13]

    // Generate the U-type immediate
    wire [31:0] immU = {immin[24:5], 12'b0}; // Concatenate bits [24:5] with 12 zeros

    // Generate the S-type immediate
    wire [31:0] immS = {{20{immin[24]}}, immin[24:18], immin[4:0]}; // Sign-extend bits [24:18] and [4:0]

    // Generate the B-type immediate
    wire [31:0] immB = {{20{immin[24]}}, immin[0], immin[23:18], immin[4:1], 1'b0}; // Sign-extend and append zero

    // Generate the J-type immediate
    wire [31:0] immJ = {{12{immin[24]}}, immin[12:5], immin[13], immin[23:14], 1'b0}; // Sign-extend and append zero

    // Use MuxKeyWithDefault to select the correct immediate value based on ExtOP
    MuxKeyWithDefault #(5, 3, 32) immtype (
        immout,
        ExtOP,
        32'b0,  // Default value
        {
            3'b000, immI,
            3'b001, immU,
            3'b010, immS,
            3'b011, immB,
            3'b100, immJ
        }
    );

endmodule