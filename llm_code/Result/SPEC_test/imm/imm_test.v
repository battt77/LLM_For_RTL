`timescale 1ns / 1ps

module tb_imm;

    reg [31:7] immin;
    reg [2:0] ExtOP;

    wire [31:0] immout;
    reg  [31:0] expected_immout;

    imm uut (
        .immin(immin), 
        .ExtOP(ExtOP), 
        .immout(immout)
    );


    function [31:0] calculate_immout(input [31:7] immin, input [2:0] ExtOP);
      case (ExtOP)
        3'b000: calculate_immout = {{20{immin[31]}}, immin[31:20]}; // I-type
        3'b001: calculate_immout = {immin[31:12], 12'b0}; // U-type
        3'b010: calculate_immout = {{20{immin[31]}}, immin[31:25], immin[11:7]}; // S-type
        3'b011: calculate_immout = {{20{immin[31]}}, immin[7], immin[30:25], immin[11:8], 1'b0}; // B-type
        3'b100: calculate_immout = {{12{immin[31]}}, immin[19:12], immin[20], immin[30:21], 1'b0}; // J-type
        default: calculate_immout = 32'b0;
      endcase
    endfunction

    initial begin
        immin = 0;
        ExtOP = 0;

        #100;
        
        repeat (50) begin
            immin = $random;
            ExtOP = $random % 8; 

            #10;

            expected_immout = calculate_immout(immin, ExtOP);
            
            if (immout !== expected_immout) begin
                $display("Mismatch at time %t: immin = %h, ExtOP = %b, expected = %h, actual = %h",
                         $time, immin, ExtOP, expected_immout, immout);
            end else begin
                $display("imm Match");
            end
        end
        
        $finish;
    end

endmodule