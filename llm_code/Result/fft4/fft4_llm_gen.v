`include "subref.v" 

module TopModule #(
    parameter DATA_WIDTH = 8    
)
(
    input wire clk,
    input wire rst_n,
    input wire en,

    // 4-point FFT, four input real and imaginary parts
    input  wire signed [DATA_WIDTH-1:0] in0_real,
    input  wire signed [DATA_WIDTH-1:0] in0_imag,
    input  wire signed [DATA_WIDTH-1:0] in1_real,
    input  wire signed [DATA_WIDTH-1:0] in1_imag,
    input  wire signed [DATA_WIDTH-1:0] in2_real,
    input  wire signed [DATA_WIDTH-1:0] in2_imag,
    input  wire signed [DATA_WIDTH-1:0] in3_real,
    input  wire signed [DATA_WIDTH-1:0] in3_imag,

    // 4-point FFT requires two stages of butterfly operations, thus adding two extra bits for width
    output wire signed [DATA_WIDTH+1:0] out0_real,
    output wire signed [DATA_WIDTH+1:0] out0_imag,
    output wire signed [DATA_WIDTH+1:0] out1_real,
    output wire signed [DATA_WIDTH+1:0] out1_imag,
    output wire signed [DATA_WIDTH+1:0] out2_real,
    output wire signed [DATA_WIDTH+1:0] out2_imag,
    output wire signed [DATA_WIDTH+1:0] out3_real,
    output wire signed [DATA_WIDTH+1:0] out3_imag,

    output wire yout_valid
);

    localparam EXPAND = 9;
    localparam POINTS = 4;

    // Rotation factors 
    reg signed [EXPAND+1:0] RO_ARRAY[POINTS-1:0][1:0];
    initial begin
        RO_ARRAY[0][0] <= 512;
        RO_ARRAY[0][1] <= 0;
        RO_ARRAY[1][0] <= 0;
        RO_ARRAY[1][1] <= -512;
        RO_ARRAY[2][0] <= -512;
        RO_ARRAY[2][1] <= 0;
        RO_ARRAY[3][0] <= 0;
        RO_ARRAY[3][1] <= 512;
    end

    wire signed [DATA_WIDTH-1:0] in_real[3:0];
    wire signed [DATA_WIDTH-1:0] in_imag[3:0];

    wire signed [DATA_WIDTH+0:0] in_real_step1[3:0];
    wire signed [DATA_WIDTH+0:0] in_imag_step1[3:0];

    wire signed [DATA_WIDTH+1:0] in_real_step2[3:0];
    wire signed [DATA_WIDTH+1:0] in_imag_step2[3:0];

    wire en_connect [3:0][1:0];

    assign en_connect[0][0] = en;
    assign en_connect[1][0] = en;

    assign in_real[0] = in0_real;
    assign in_imag[0] = in0_imag;
    assign in_real[1] = in2_real;
    assign in_imag[1] = in2_imag;
    assign in_real[2] = in1_real;
    assign in_imag[2] = in1_imag;
    assign in_real[3] = in3_real;
    assign in_imag[3] = in3_imag;

    SubModule #(
        .DATA_WIDTH(DATA_WIDTH), .EXPAND(EXPAND)
    )  butterfly_unit_0_0 (
        .clk(clk),
        .rst_n(rst_n),
        .en(en_connect[0][0]),
        .in1_real(in_real[0]),
        .in1_imag(in_imag[0]),
        .in2_real(in_real[1]),
        .in2_imag(in_imag[1]),
        .ro_real(RO_ARRAY[0][0]),
        .ro_imag(RO_ARRAY[0][1]),
        .out1_real(in_real_step1[0]),
        .out1_imag(in_imag_step1[0]),
        .out2_real(in_real_step1[1]),
        .out2_imag(in_imag_step1[1]),
        .valid(en_connect[0][1])
    );

    SubModule #(
        .DATA_WIDTH(DATA_WIDTH), .EXPAND(EXPAND)
    )  butterfly_unit_0_1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(en_connect[1][0]),
        .in1_real(in_real[2]),
        .in1_imag(in_imag[2]),
        .in2_real(in_real[3]),
        .in2_imag(in_imag[3]),
        .ro_real(RO_ARRAY[0][0]),
        .ro_imag(RO_ARRAY[0][1]),
        .out1_real(in_real_step1[2]),
        .out1_imag(in_imag_step1[2]),
        .out2_real(in_real_step1[3]),
        .out2_imag(in_imag_step1[3]),
        .valid(en_connect[1][1])
    );

    assign en_connect[2][0] = en_connect[0][1];
    assign en_connect[3][0] = en_connect[1][1];

    SubModule #(
        .DATA_WIDTH(DATA_WIDTH+1), .EXPAND(EXPAND)
    )  butterfly_unit_1_0 (
        .clk(clk),
        .rst_n(rst_n),
        .en(en_connect[2][0]),
        .in1_real(in_real_step1[0]),
        .in1_imag(in_imag_step1[0]),
        .in2_real(in_real_step1[2]),
        .in2_imag(in_imag_step1[2]),
        .ro_real(RO_ARRAY[0][0]),
        .ro_imag(RO_ARRAY[0][1]),
        .out1_real(in_real_step2[0]),
        .out1_imag(in_imag_step2[0]),
        .out2_real(in_real_step2[2]),
        .out2_imag(in_imag_step2[2]),
        .valid(en_connect[2][1])
    );

    SubModule #(
        .DATA_WIDTH(DATA_WIDTH+1), .EXPAND(EXPAND)
    )  butterfly_unit_1_1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(en_connect[3][0]),
        .in1_real(in_real_step1[1]),
        .in1_imag(in_imag_step1[1]),
        .in2_real(in_real_step1[3]),
        .in2_imag(in_imag_step1[3]),
        .ro_real(RO_ARRAY[1][0]),
        .ro_imag(RO_ARRAY[1][1]),
        .out1_real(in_real_step2[1]),
        .out1_imag(in_imag_step2[1]),
        .out2_real(in_real_step2[3]),
        .out2_imag(in_imag_step2[3]),
        .valid(en_connect[3][1])
    );

    assign yout_valid = en_connect[3][1];

    assign out0_real = in_real_step2[0];
    assign out0_imag = in_imag_step2[0];
    assign out1_real = in_real_step2[1];
    assign out1_imag = in_imag_step2[1];
    assign out2_real = in_real_step2[2];
    assign out2_imag = in_imag_step2[2];
    assign out3_real = in_real_step2[3];
    assign out3_imag = in_imag_step2[3];

endmodule
