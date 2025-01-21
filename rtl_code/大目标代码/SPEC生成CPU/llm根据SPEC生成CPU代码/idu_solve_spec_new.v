module idu(
    input [6:0] op,
    input [2:0] func3,
    input [31:12] func7, // Defined as [31:12]
    input [31:0] inst,
    output reg [2:0] ExtOP,
    output reg [3:0] ALUctr,
    output reg Wen,
    output reg ALUAsrc,
    output reg ALUBsrc,
    output reg [2:0] wdctr,
    output reg [3:0] pcctr,
    output reg datawen,
    output reg valid,
    output reg [7:0] datamask,
    output reg csr_rs,
    output reg ecall,
    output reg mret,
    output reg csr_read,
    output reg csr_write
);

reg [3:0] alusel;
reg [7:0] mask;
reg [3:0] csr_sel;

// MuxKeyWithDefault instantiation for datamask
MuxKeyWithDefault #(5, 3, 8) masksel (
    mask, func3, 8'b00000000, {
    3'b010, 8'b00001111, // sw, lw
    3'b001, 8'b00000011, // sh, lh
    3'b000, 8'b00000001, // sb, lb
    3'b100, 8'b00000001, // lbu
    3'b101, 8'b00000011  // lhu
});

// MuxKeyWithDefault instantiation for ALUctr
MuxKeyWithDefault #(3, 3, 4) andsel (
    alusel, func3, 4'b0010, {
    3'b111, 4'b0010, // and, andi
    3'b110, 4'b0011, // or, ori
    3'b100, 4'b0100  // xor, xori
});

// CSR Logic
always @(csr_sel) begin
    case (csr_sel)
        4'b0001: begin // ecall
            csr_rs = 0; ecall = 1; mret = 0; csr_read = 0; csr_write = 0;
        end
        4'b0010: begin // mret
            csr_rs = 0; ecall = 0; mret = 1; csr_read = 0; csr_write = 0;
        end
        4'b0011: begin // csrrw
            csr_rs = 0; ecall = 0; mret = 0; csr_read = 1; csr_write = 1;
        end
        4'b0100: begin // csrrs
            csr_rs = 1; ecall = 0; mret = 0; csr_read = 1; csr_write = 1;
        end
        default: begin
            csr_rs = 0; ecall = 0; mret = 0; csr_read = 0; csr_write = 0;
        end
    endcase
end

// Sub-Decoding Using op/func3/func7
always @(*) begin
    case (op)
        7'b1110011: begin // System/CSR
            case (func3)
                3'b000: begin
                    if (inst == 32'b00000000000000000000000001110011) begin
                        ExtOP = 3'b000; Wen = 0; ALUAsrc = 1; ALUBsrc = 0;
                        ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b1001;
                        datawen = 0; valid = 0; csr_sel = 4'b0001; datamask = 8'b00000000;
                    end else if (inst == 32'b00110000001000000000000001110011) begin
                        ExtOP = 3'b000; Wen = 0; ALUAsrc = 1; ALUBsrc = 0;
                        ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b1010;
                        datawen = 0; valid = 0; csr_sel = 4'b0010; datamask = 8'b00000000;
                    end else begin
                        ExtOP = 3'b000; Wen = 0; ALUAsrc = 1; ALUBsrc = 0;
                        ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0000;
                        datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                    end
                end
                3'b001: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 0;
                    ALUctr = 4'b0000; wdctr = 3'b111; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0011; datamask = 8'b00000000;
                end
                3'b010: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 0;
                    ALUctr = 4'b0000; wdctr = 3'b111; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0100; datamask = 8'b00000000;
                end
                default: begin
                    ExtOP = 3'b000; Wen = 0; ALUAsrc = 1; ALUBsrc = 0;
                    ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
            endcase
        end
        7'b0110111, 7'b0010111: begin // U-type
            ExtOP = 3'b001; Wen = 1; ALUAsrc = 0; ALUBsrc = 0;
            ALUctr = 4'b0000; wdctr = {1'b0, op[6:5]}; pcctr = 4'b0000;
            datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
        end
        7'b0010011: begin // I-type
            case (func3)
                3'b000: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 0;
                    ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b101: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 0;
                    ALUctr = {3'b011, func7[30]}; wdctr = 3'b000; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b001: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 0;
                    ALUctr = 4'b0101; wdctr = 3'b000; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b011: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 0;
                    ALUctr = 4'b0000; wdctr = 3'b100; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b111, 3'b110, 3'b100: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 0;
                    ALUctr = alusel; wdctr = 3'b000; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                default: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 0;
                    ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
            endcase
        end
        7'b0000011: begin // Load - I-type
            ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 0;
            ALUctr = 4'b0000; wdctr = 3'b011; pcctr = 4'b0000;
            datawen = 0; valid = 1; csr_sel = 4'b0000; datamask = mask;
        end
        7'b0100011: begin // Store - S-type
            ExtOP = 3'b010; Wen = 0; ALUAsrc = 1; ALUBsrc = 0;
            ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0000;
            datawen = 1; valid = 1; csr_sel = 4'b0000; datamask = mask;
        end
        7'b0110011: begin // R-type
            case (func3)
                3'b000: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = {3'b000, func7[30]}; wdctr = 3'b000; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b010: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 0; ALUBsrc = 0;
                    ALUctr = 4'b0010; wdctr = 3'b110; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b001: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = 4'b0101; wdctr = 3'b000; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b101: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = {func7[30], 3'b110}; wdctr = 3'b000; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b011: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 0; ALUBsrc = 0;
                    ALUctr = 4'b0010; wdctr = 3'b101; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b111, 3'b110, 3'b100: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = alusel; wdctr = 3'b000; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                default: begin
                    ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
            endcase
        end
        7'b1100011: begin // Branch - B-type
            case (func3)
                3'b000: begin
                    ExtOP = 3'b011; Wen = 0; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0011;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b001: begin
                    ExtOP = 3'b011; Wen = 0; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0100;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b100: begin
                    ExtOP = 3'b011; Wen = 0; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0110;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b101: begin
                    ExtOP = 3'b011; Wen = 0; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0111;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b110: begin
                    ExtOP = 3'b011; Wen = 0; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0101;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                3'b111: begin
                    ExtOP = 3'b011; Wen = 0; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b1000;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
                default: begin
                    ExtOP = 3'b011; Wen = 0; ALUAsrc = 1; ALUBsrc = 1;
                    ALUctr = 4'b0000; wdctr = 3'b000; pcctr = 4'b0011;
                    datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
                end
            endcase
        end
        7'b1100111: begin // JALR
            ExtOP = 3'b000; Wen = 1; ALUAsrc = 1; ALUBsrc = 0;
            ALUctr = 4'b0000; wdctr = 3'b010; pcctr = 4'b0010;
            datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
        end
        7'b1101111: begin // JAL
            ExtOP = 3'b100; Wen = 1; ALUAsrc = 0; ALUBsrc = 0;
            ALUctr = 4'b0000; wdctr = 3'b010; pcctr = 4'b0001;
            datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
        end
        default: begin // Default case
            ExtOP = 3'b000; Wen = 0; ALUAsrc = 1; ALUBsrc = 0;
            ALUctr = 4'b0000; wdctr = 3'b010; pcctr = 4'b0000;
            datawen = 0; valid = 0; csr_sel = 4'b0000; datamask = 8'b00000000;
        end
    endcase
end

endmodule