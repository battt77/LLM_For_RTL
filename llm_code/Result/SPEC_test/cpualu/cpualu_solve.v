module cpualu (
    input [31:0] ina,
    input [31:0] inb,
    input [3:0] sel,
    output [31:0] out
);

    wire [31:0] inb1, addf, and_out, or_out, xor_out, sll, srl, sra;
    wire borrow;

    // Logic for addition and subtraction
    assign inb1 = inb ^ {32{sel[0]}};
    assign {borrow, addf} = ina + inb1 + {{31{1'b0}}, sel[0]};

    // Logic for bitwise operations
    assign and_out = ina & inb;
    assign or_out = ina | inb;
    assign xor_out = ina ^ inb;

    // Logic for shift operations
    assign sll = ina << inb[4:0];
    assign srl = ina >> inb[4:0];
    assign sra = ({32{ina[31]}} << (6'd32 - {1'b0, inb[4:0]})) | (ina >> inb[4:0]);

    // Multiplexer using MuxKeyWithDefault
    MuxKeyWithDefault #(32, 4, 32'b0, 32) mux (
        out,
        sel,
        32'b0,  // Default output
        {
            4'b0000, addf,    // Addition
            4'b0001, addf,    // Subtraction
            4'b0010, and_out, // Bitwise AND
            4'b0011, or_out,  // Bitwise OR
            4'b0100, xor_out, // Bitwise XOR
            4'b0101, sll,     // Logical shift left
            4'b0110, srl,     // Logical shift right
            4'b0111, sra,     // Arithmetic shift right
            4'b1110, sra      // Arithmetic shift right (alternative)
        }
    );

endmodule