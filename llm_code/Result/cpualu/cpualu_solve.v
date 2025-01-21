module cpualu(
    input [31:0] ina, inb,
    input [3:0] sel,
    output [31:0] out
);

    wire [31:0] addf, andf, orf, xorf;
    wire [31:0] sll, srl, srai;
    wire [31:0] sra;
    wire borrow;
    wire [31:0] inb1;

    // Compute bitwise operations
    assign andf = ina & inb;
    assign orf = ina | inb;
    assign xorf = ina ^ inb;

    // Prepare the inb1 for addition/subtraction
    assign inb1 = inb ^ {32{sel[0]}};

    // Perform addition or subtraction based on sel[0]
    assign {borrow, addf} = ina + inb1 + {{31{1'b0}}, sel[0]};

    // Logical and arithmetic shifts
    assign sll = ina << inb[4:0];
    assign srl = ina >> inb[4:0];
    assign srai = ({32{ina[31]}} << (6'd32 - {1'b0, inb[4:0]})) | (ina >> inb[4:0]);
    assign sra = ({32{ina[31]}} << (6'd32 - {1'b0, inb[4:0]})) | (ina >> inb[4:0]);

    // Use MuxKeyWithDefault to select the correct operation
    MuxKeyWithDefault #(9, 4, 32) alu1 (
        out, 
        sel, 
        32'b0, 
        {
            4'b0000, addf, // Addition
            4'b0001, addf, // Subtraction
            4'b0010, andf, // Bitwise AND
            4'b0011, orf,  // Bitwise OR
            4'b0100, xorf, // Bitwise XOR
            4'b0101, sll,  // Logical shift left
            4'b0110, srl,  // Logical shift right
            4'b0111, srai, // Arithmetic shift right
            4'b1110, sra   // Arithmetic shift right (alternative)
        }
    );
endmodule