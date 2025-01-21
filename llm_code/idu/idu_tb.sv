`timescale 1ns / 1ps

module idu_tb;

    reg [31:0] inst;

    wire [2:0] ExtOP1;
    wire [3:0] ALUctr1;
    wire Wen1;
    wire [0:0] ALUAsrc1;
    wire [0:0] ALUBsrc1;
    wire [2:0] wdctr1;
    wire [3:0] pcctr1;
    wire datawen1;
    wire valid1;
    wire [7:0] datamask1;

    wire [2:0] ExtOP2;
    wire [3:0] ALUctr2;
    wire Wen2;
    wire [0:0] ALUAsrc2;
    wire [0:0] ALUBsrc2;
    wire [2:0] wdctr2;
    wire [3:0] pcctr2;
    wire datawen2;
    wire valid2;
    wire [7:0] datamask2;

    integer i;

    // reg [31:0] inst;

    // reg ExtOP1, ExtOP2;
    // reg ALUctr1, ALUctr2;
    // reg Wen1, Wen2;
    // reg ALUAsrc1, ALUAsrc2;
    // reg ALUBsrc1, ALUBsrc2;
    // reg wdctr1, wdctr2;
    // reg pcctr1, pcctr2;
    // reg datawen1, datawen2;
    // reg valid1, valid2;
    // reg datamask1, datamask2;

    reg [31:0] inst_list[40:0];

    idu1 uut_ref (
        .inst(inst),
        .ExtOP(ExtOP1),
        .ALUctr(ALUctr1),
        .Wen(Wen1),
        .ALUAsrc(ALUAsrc1),
        .ALUBsrc(ALUBsrc1),
        .wdctr(wdctr1),
        .pcctr(pcctr1),
        .datawen(datawen1),
        .valid(valid1),
        .datamask(datamask1)
    );

    idu uut_llm (
        .inst(inst),
        .ExtOP(ExtOP2),
        .ALUctr(ALUctr2),
        .Wen(Wen2),
        .ALUAsrc(ALUAsrc2),
        .ALUBsrc(ALUBsrc2),
        .wdctr(wdctr2),
        .pcctr(pcctr2),
        .datawen(datawen2),
        .valid(valid2),
        .datamask(datamask2)
    );

    // initial begin
    //     inst = 0;

    //     #100;

    //     inst = 32'h00009117;
    //     #10; 
        
    //     if (ExtOP1 !== ExtOP2 ||
    //         ALUctr1 !== ALUctr2 ||
    //         Wen1 !== Wen2 ||
    //         ALUAsrc1 !== ALUAsrc2 ||
    //         ALUBsrc1 !== ALUBsrc2 ||
    //         wdctr1 !== wdctr2 ||
    //         pcctr1 !== pcctr2 ||
    //         datawen1 !== datawen2 ||
    //         valid1 !== valid2 ||
    //         datamask1 !== datamask2) begin
    //         $display("Mismatch at Time %t: inst = %h", $time, inst);
    //         $display("ExtOP: %b vs %b, ALUctr: %b vs %b, Wen: %b vs %b, ALUAsrc: %b vs %b, ALUBsrc: %b vs %b",
    //                  ExtOP1, ExtOP2, ALUctr1, ALUctr2, Wen1, Wen2, ALUAsrc1, ALUAsrc2, ALUBsrc1, ALUBsrc2);
    //         $display("wdctr: %b vs %b, pcctr: %b vs %b, datawen: %b vs %b, valid: %b vs %b, datamask: %b vs %b",
    //                  wdctr1, wdctr2, pcctr1, pcctr2, datawen1, datawen2, valid1, valid2, datamask1, datamask2);
    //         $stop;
    //     end else begin
    //         $display("Test Case Passed at Time %t: inst = %h", $time, inst);
    //     end
        
    //     $finish;
    // end

    initial begin
        
        inst_list[0] = 32'h00009117;
        inst_list[1] = 32'hffc10113; //addi
        inst_list[2] = 32'h00154513; //xori
        inst_list[3] = 32'h0016e693; //ori
        inst_list[4] = 32'h00153513; //squz sltiu
        inst_list[5] = 32'h0f74f793; //andi
        inst_list[9] = 32'h00249493; //slli
        inst_list[10] = 32'h0016d693; //srli
        inst_list[11] = 32'h41f55793; //srai
        inst_list[12] = 32'h00f407b3; //add
        inst_list[13] = 32'h40f50533; //sub
        inst_list[14] = 32'h00f717b3; //sll
        inst_list[13] = 32'h00e6a6b3; //slt
        inst_list[14] = 32'h00d63333; //sltu
        inst_list[15] = 32'h00a7c533; //xor
        inst_list[16] = 32'h00d56533; //or
        inst_list[17] = 32'h0157f7b3; //and
        inst_list[18] = 32'h00855533; //srl
        inst_list[19] = 32'h40955533; //sra
        inst_list[20] = 32'h000dc683; //lbu
        inst_list[21] = 32'h00049503; //lh
        inst_list[22] = 32'hf7c7d703; //lhu
        inst_list[23] = 32'h00412403; //lw
        inst_list[24] = 32'h00c78023; //sb
        inst_list[25] = 32'hfef61fa3; //sh
        inst_list[26] = 32'h00112423; //sw
        inst_list[27] = 32'hf79ff0ef; //jal
        inst_list[28] = 32'h000780e7; //jalr
        inst_list[29] = 32'hfaf48ae3; //beq
        inst_list[30] = 32'hf4050ae3; //beqz
        inst_list[31] = 32'hfaf41ce3; //bne
        inst_list[32] = 32'h040c1a63; //bnez
        inst_list[33] = 32'h02a7c863; //blt
        inst_list[34] = 32'h10f76e63; //bltu
        inst_list[35] = 32'h0005ca63; //bltz
        inst_list[36] = 32'h050bd063; //bge
        inst_list[37] = 32'h00e67463; //bgeu
        inst_list[38] = 32'hfe0558e3; //bgtz
        inst_list[39] = 32'h000027b7; //lui
        inst_list[40] = 32'h00007c63; //auipc

        for (i = 0; i < 41; i = i + 1) begin
            inst = inst_list[i];
            #10;

            if (ExtOP1 !== ExtOP2 ||
                ALUctr1 !== ALUctr2 ||
                Wen1 !== Wen2 ||
                ALUAsrc1 !== ALUAsrc2 ||
                ALUBsrc1 !== ALUBsrc2 ||
                wdctr1 !== wdctr2 ||
                pcctr1 !== pcctr2 ||
                datawen1 !== datawen2 ||
                valid1 !== valid2 ||
                datamask1 !== datamask2) begin
                $display("Mismatch at Time %t: inst = %h", $time, inst);
                $display("ExtOP: %b vs %b, ALUctr: %b vs %b, Wen: %b vs %b, ALUAsrc: %b vs %b, ALUBsrc: %b vs %b",
                        ExtOP1, ExtOP2, ALUctr1, ALUctr2, Wen1, Wen2, ALUAsrc1, ALUAsrc2, ALUBsrc1, ALUBsrc2);
                $display("wdctr: %b vs %b, pcctr: %b vs %b, datawen: %b vs %b, valid: %b vs %b, datamask: %b vs %b",
                        wdctr1, wdctr2, pcctr1, pcctr2, datawen1, datawen2, valid1, valid2, datamask1, datamask2);
                $stop;
            end else begin
                $display("Test Case Passed at Time %t: inst = %h", $time, inst);
            end
        end

        $finish;
    end

    initial begin
        #10000
        $display("Time out");
        $finish;
    end

endmodule