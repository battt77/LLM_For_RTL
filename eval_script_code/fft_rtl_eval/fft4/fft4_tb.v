`timescale 1ps / 1ps

module fft4_tb;

    // 数据宽度
    parameter DATA_WIDTH = 8;

    // 输入数据
    reg signed [DATA_WIDTH-1:0] x0_real;
    reg signed [DATA_WIDTH-1:0] x0_imag;
    reg signed [DATA_WIDTH-1:0] x1_real;
    reg signed [DATA_WIDTH-1:0] x1_imag;
    reg signed [DATA_WIDTH-1:0] x2_real;
    reg signed [DATA_WIDTH-1:0] x2_imag;
    reg signed [DATA_WIDTH-1:0] x3_real;
    reg signed [DATA_WIDTH-1:0] x3_imag;

    // 输出数据
    wire signed [DATA_WIDTH+1:0] y0_real;
    wire signed [DATA_WIDTH+1:0] y0_imag;
    wire signed [DATA_WIDTH+1:0] y1_real;
    wire signed [DATA_WIDTH+1:0] y1_imag;
    wire signed [DATA_WIDTH+1:0] y2_real;
    wire signed [DATA_WIDTH+1:0] y2_imag;
    wire signed [DATA_WIDTH+1:0] y3_real;
    wire signed [DATA_WIDTH+1:0] y3_imag;

    // 数据有效信号
    wire valid;

    // 仿真时钟
    reg clk = 0;
    always #5 clk = !clk;

    // fft4模块实例化
    fft4 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) fft4_inst (
        .clk(clk),
        .rst_n(1'b1),
        .en(1'b1),
        .in0_real(x0_real),
        .in0_imag(x0_imag),
        .in1_real(x1_real),
        .in1_imag(x1_imag),
        .in2_real(x2_real),
        .in2_imag(x2_imag),
        .in3_real(x3_real),
        .in3_imag(x3_imag),
        .out0_real(y0_real),
        .out0_imag(y0_imag),
        .out1_real(y1_real),
        .out1_imag(y1_imag),
        .out2_real(y2_real),
        .out2_imag(y2_imag),
        .out3_real(y3_real),
        .out3_imag(y3_imag),
        .yout_valid(valid)
    );

    // 模拟输入数据
    initial begin
        x0_real =  1;
        x0_imag =  0;
        x1_real =  2;
        x1_imag =  0;
        x2_real =  -1;
        x2_imag =  0;
        x3_real =  3;
        x3_imag =  0;
        #100;
		$finish;
    end

    initial begin
        $dumpfile("fft4_tb.vcd"); // 指定用作dumpfile的文件
        $dumpvars; // dump all vars
    end

endmodule
