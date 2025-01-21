`timescale 1ns/100ps

module TopModule (
    input                    clk,
    input                    rstn,
    input                    en,
    input signed [23:0]      x0_real,
    input signed [23:0]      x0_imag,
    input signed [23:0]      x1_real,
    input signed [23:0]      x1_imag,
    input signed [23:0]      x2_real,
    input signed [23:0]      x2_imag,
    input signed [23:0]      x3_real,
    input signed [23:0]      x3_imag,
    output                   yout_valid,
    output signed [23:0]     y0_real,
    output signed [23:0]     y0_imag,
    output signed [23:0]     y1_real,
    output signed [23:0]     y1_imag,
    output signed [23:0]     y2_real,
    output signed [23:0]     y2_imag,
    output signed [23:0]     y3_real,
    output signed [23:0]     y3_imag
);

    // Operating data
    wire signed [23:0] xm_real[2:0][3:0];
    wire signed [23:0] xm_imag[2:0][3:0];
    wire en_connect[5:0];

    assign en_connect[0] = en;
    assign en_connect[1] = en;

    // Rotation factors for 4-point FFT
    wire signed [15:0] factor_real[1:0];
    wire signed [15:0] factor_imag[1:0];
    assign factor_real[0] = 16'h2000; // 1 (scaled)
    assign factor_imag[0] = 16'h0000; // 0
    assign factor_real[1] = 16'h0000; // 0
    assign factor_imag[1] = 16'hE000; // -1 (scaled)

    // Input initialization
    assign xm_real[0][0] = x0_real;
    assign xm_real[0][1] = x2_real;
    assign xm_real[0][2] = x1_real;
    assign xm_real[0][3] = x3_real;

    assign xm_imag[0][0] = x0_imag;
    assign xm_imag[0][1] = x2_imag;
    assign xm_imag[0][2] = x1_imag;
    assign xm_imag[0][3] = x3_imag;

    // Butterfly instantiation
    genvar m, k;
    generate
        for (m = 0; m <= 1; m = m + 1) begin: stage
            for (k = 0; k <= 1; k = k + 1) begin: unit
                SubModule u_butter (
                    .clk(clk),
                    .rstn(rstn),
                    .en(en_connect[m*2 + k]),
                    .xp_real(xm_real[m][k < 1 ? 0 : k+1-m]),
                    .xp_imag(xm_imag[m][k < 1 ? 0 : k+1-m]),
                    .xq_real(xm_real[m][k < 1 ? 1+m : k+2]),
                    .xq_imag(xm_imag[m][k < 1 ? 1+m : k+2]),
                    .factor_real(factor_real[(m & k) ? 1 : 0]),
                    .factor_imag(factor_imag[(m & k) ? 1 : 0]),
                    .valid(en_connect[(m+1)*2 + k]),
                    .yp_real(xm_real[m+1][k < 1 ? 0 : k+1-m]),
                    .yp_imag(xm_imag[m+1][k < 1 ? 0 : k+1-m]),
                    .yq_real(xm_real[m+1][k < 1 ? 1+m : k+2]),
                    .yq_imag(xm_imag[m+1][k < 1 ? 1+m : k+2])
                );
            end
        end
    endgenerate

    assign yout_valid = en_connect[5];
    assign y0_real = xm_real[2][0];
    assign y0_imag = xm_imag[2][0];
    assign y1_real = xm_real[2][1];
    assign y1_imag = xm_imag[2][1];
    assign y2_real = xm_real[2][2];
    assign y2_imag = xm_imag[2][2];
    assign y3_real = xm_real[2][3];
    assign y3_imag = xm_imag[2][3];

endmodule