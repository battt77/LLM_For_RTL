module idu(
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
    output reg [7:0] datamask
);

    wire [6:0] op = inst[6:0];
    wire [2:0] func3 = inst[14:12];
    wire func7_bit = inst[30];
    wire [7:0] mask;
    wire [3:0] alusel;

    // MuxKeyWithDefault for datamask
    MuxKeyWithDefault #(5, 3, 8) masksel(mask, func3, 8'b00000000, {
        3'b010, 8'b00001111, // sw lw
        3'b001, 8'b00000011, // sh lh
        3'b000, 8'b00000001, // sb lb
        3'b100, 8'b00000001, // lbu
        3'b101, 8'b00000011  // lhu
    });

    // MuxKeyWithDefault for ALU control selection
    MuxKeyWithDefault #(3, 3, 4) andsel(alusel, func3, 4'b0010, {
        3'b111, 4'b0010, // and andi
        3'b110, 4'b0011, // or ori
        3'b100, 4'b0100  // xor xori
    });

    always @(*) begin
        case(op)
            7'b0110111, 7'b0010111: begin // U-type
                ExtOP = 3'b001;
                Wen = 1;
                ALUAsrc = 0;
                ALUBsrc = 0;
                ALUctr = 4'b0000;
                wdctr = {1'b0, op[6:5]};
                pcctr = 4'b0000;
                datawen = 0;
                valid = 0;
                datamask = 8'b00000000;
            end
            7'b0010011: begin // I-type
                case(func3)
                    3'b000: begin // addi
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 0;
                        ALUctr = 4'b0000;
                        wdctr = 3'b000;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b101: begin // srli, srai
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 0;
                        ALUctr = {3'b011, func7_bit};
                        wdctr = 3'b000;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b001: begin // slli
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 0;
                        ALUctr = 4'b0101;
                        wdctr = 3'b000;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b011: begin // sltiu pseudo instruction seqz
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 0;
                        ALUctr = 4'b0000;
                        wdctr = 3'b100;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b111, 3'b110, 3'b100: begin // andi ori xori
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 0;
                        ALUctr = alusel;
                        wdctr = 3'b000;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    default: begin // addi
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 0;
                        ALUctr = 4'b0000;
                        wdctr = 3'b000;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                endcase
            end

            7'b0000011: begin // I-type load
                case(func3)
                    3'b000, 3'b001, 3'b010: begin // lb lh lw
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 0;
                        ALUctr = 4'b0000;
                        wdctr = 3'b011;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 1;
                        datamask = mask;
                    end
                    3'b100: begin // lbu
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 0;
                        ALUctr = 4'b0000;
                        wdctr = 3'b011;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 1;
                        datamask = mask;
                    end
                    3'b101: begin // lhu
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 0;
                        ALUctr = 4'b0000;
                        wdctr = 3'b011;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 1;
                        datamask = mask;
                    end
                    default: begin
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 0;
                        ALUctr = 4'b0000;
                        wdctr = 3'b011;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 1;
                        datamask = mask;
                    end
                endcase
            end
            7'b0100011: begin // S-type
                ExtOP = 3'b010;
                Wen = 0;
                ALUAsrc = 1;
                ALUBsrc = 0;
                ALUctr = 4'b0000;
                wdctr = 3'b000;
                pcctr = 4'b0000;
                datawen = 1;
                valid = 1;
                datamask = mask;
            end
            7'b0110011: begin // R-type
                case(func3)
                    3'b000: begin // add or sub
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = {3'b000, func7_bit};
                        wdctr = 3'b000;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b010: begin // slt
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 0;
                        ALUBsrc = 0;
                        ALUctr = 4'b0010;
                        wdctr = 3'b110;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b001: begin // sll
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = 4'b0101;
                        wdctr = 3'b000;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b101: begin // srl sra
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = {func7_bit, 3'b110};
                        wdctr = 3'b000;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b011: begin // sltu
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 0;
                        ALUBsrc = 0;
                        ALUctr = 4'b0010;
                        wdctr = 3'b101;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b111, 3'b110, 3'b100: begin // and or xor
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = alusel;
                        wdctr = 3'b000;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    default: begin // add
                        ExtOP = 3'b000;
                        Wen = 1;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = 4'b0000;
                        wdctr = 3'b000;
                        pcctr = 4'b0000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                endcase
            end
            7'b1100011: begin // B-type
                case(func3)
                    3'b000: begin // beq
                        ExtOP = 3'b011;
                        Wen = 0;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = 4'b0000;
                        wdctr = 3'b000;
                        pcctr = 4'b0011;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b001: begin // bne
                        ExtOP = 3'b011;
                        Wen = 0;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = 4'b0000;
                        wdctr = 3'b000;
                        pcctr = 4'b0100;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b100: begin // blt
                        ExtOP = 3'b011;
                        Wen = 0;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = 4'b0000;
                        wdctr = 3'b000;
                        pcctr = 4'b0110;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b101: begin // bge
                        ExtOP = 3'b011;
                        Wen = 0;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = 4'b0000;
                        wdctr = 3'b000;
                        pcctr = 4'b0111;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b110: begin // bltu
                        ExtOP = 3'b011;
                        Wen = 0;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = 4'b0000;
                        wdctr = 3'b000;
                        pcctr = 4'b0101;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    3'b111: begin // bgeu
                        ExtOP = 3'b011;
                        Wen = 0;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = 4'b0000;
                        wdctr = 3'b000;
                        pcctr = 4'b1000;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                    default: begin // beq
                        ExtOP = 3'b011;
                        Wen = 0;
                        ALUAsrc = 1;
                        ALUBsrc = 1;
                        ALUctr = 4'b0000;
                        wdctr = 3'b000;
                        pcctr = 4'b0011;
                        datawen = 0;
                        valid = 0;
                        datamask = 8'b00000000;
                    end
                endcase
            end
            7'b1100111: begin // jalr
                ExtOP = 3'b000;
                Wen = 1;
                ALUAsrc = 1;
                ALUBsrc = 0;
                ALUctr = 4'b0000;
                wdctr = 3'b010;
                pcctr = 4'b0010;
                datawen = 0;
                valid = 0;
                datamask = 8'b00000000;
            end
            7'b1101111: begin // jal
                ExtOP = 3'b100;
                Wen = 1;
                ALUAsrc = 0;
                ALUBsrc = 0;
                ALUctr = 4'b0000;
                wdctr = 3'b010;
                pcctr = 4'b0001;
                datawen = 0;
                valid = 0;
                datamask = 8'b00000000;
            end
            default: begin
                ExtOP = 3'b000;
                Wen = 0;
                ALUAsrc = 1;
                ALUBsrc = 0;
                ALUctr = 4'b0000;
                wdctr = 3'b010;
                pcctr = 4'b0000;
                datawen = 0;
                valid = 0;
                datamask = 8'b00000000;
            end
        endcase
    end
endmodule