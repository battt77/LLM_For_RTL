`timescale 1ns / 1ps

module cpualu_tb;

    reg [31:0] ina;
    reg [31:0] inb;
    reg [3:0] sel;

    wire [31:0] out;

    cpualu uut (
        .ina(ina), 
        .inb(inb), 
        .sel(sel), 
        .out(out)
    );

    wire [31:0] expected_add;
    wire [31:0] expected_and;
    wire [31:0] expected_or;
    wire [31:0] expected_xor;
    wire [31:0] expected_sll;
    wire [31:0] expected_srl;
    wire [31:0] expected_srai;
    wire [31:0] expected_sra;

    assign expected_add = ina + inb;
    assign expected_and = ina & inb;
    assign expected_or = ina | inb;
    assign expected_xor = ina ^ inb;
    assign expected_sll = ina << inb[4:0];
    assign expected_srl = ina >> inb[4:0];
    //assign expected_srai = ina >>> inb[4:0];
    assign expected_srai=({32{ina[31]}} << (6'd32-{1'b0,inb[4:0]}))|(ina>>inb[4:0]);
    assign expected_sra = expected_srai; 
    // initial begin
    // $fsdbDumpfile("cpualu_tb.fsdb");
    // $fsdbDumpvars;
    // end
    initial begin
        ina = 0;
        inb = 0;
        sel = 0;

        #10;
        
        repeat (100) begin
            #10; 
            ina = $random;
            inb = $random;
            sel = $random % 16; 

            #10;
            case (sel)
                4'b0000: begin
                    if (out !== expected_add) 
                        $display("ADD mismatch,Time = %t, ina = %h, inb = %h, sel = %h, out = %h",$time, ina, inb, sel, out);
                    else $display("ADD match");
                end
                4'b0001: begin//no sub inst
                    // if (out !== expected_sub) 
                    //     $display("SUB mismatch,Time = %t, ina = %h, inb = %h, sel = %h, out = %h",$time, ina, inb, sel, out);
                    // else $display("SUB match");
                end
                4'b0010: begin
                    if (out !== expected_and) 
                        $display("AND mismatch,Time = %t, ina = %h, inb = %h, sel = %h, out = %h",$time, ina, inb, sel, out);
                    else $display("AND match");
                end
                4'b0011: begin
                    if (out !== expected_or) 
                        $display("OR mismatch,Time = %t, ina = %h, inb = %h, sel = %h, out = %h",$time, ina, inb, sel, out);
                    else $display("OR match");
                end
                4'b0100: begin
                    if (out !== expected_xor) 
                        $display("XOR mismatch,Time = %t, ina = %h, inb = %h, sel = %h, out = %h",$time, ina, inb, sel, out);
                    else $display("XOR match");
                end
                4'b0101: begin
                    if (out !== expected_sll) 
                        $display("SLL mismatch,Time = %t, ina = %h, inb = %h, sel = %h, out = %h",$time, ina, inb, sel, out);
                    else $display("SLL match");
                end
                4'b0110: begin
                    if (out !== expected_srl) 
                        $display("SRL mismatch,Time = %t, ina = %h, inb = %h, sel = %h, out = %h",$time, ina, inb, sel, out);
                    else $display("SRL match");
                end
                4'b0111: begin
                    if (out !== expected_srai) 
                        $display("SRAI mismatch,Time = %t, ina = %h, inb = %h, sel = %h, out = %h",$time, ina, inb, sel, out);
                    else $display("SRAI match");
                end
                4'b1110: begin
                    if (out !== expected_sra) 
                        $display("SRA mismatch,Time = %t, ina = %h, inb = %h, sel = %h, out = %h",$time, ina, inb, sel, out);
                    else $display("SRA match");
                end
                default:begin end 
            endcase
        end
        
        $finish;
    end

endmodule