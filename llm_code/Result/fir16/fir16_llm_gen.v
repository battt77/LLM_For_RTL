module TopModule
(
    input                rstn,
    input                clk, // Fs=2K
    input                xin_en,
    input        [11:0]  xin,
    output               yout_valid,
    output       [28:0]  yout
);

    reg [3:0]            en_r;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            en_r <= 4'b0;
        end else begin
            en_r <= {en_r[2:0], xin_en};
        end
    end

    reg [11:0]    xin_reg[15:0];
    integer i, j;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 16; i = i + 1) begin
                xin_reg[i] <= 12'b0;
            end
        end else if (xin_en) begin
            for (j = 0; j < 15; j = j + 1) begin
                xin_reg[j + 1] <= xin_reg[j];
            end
            xin_reg[0] <= xin;
        end
    end

    reg [12:0] add_reg[7:0];
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 8; i = i + 1) begin
                add_reg[i] <= 13'd0;
            end
        end else if (en_r[0]) begin
            for (i = 0; i < 8; i = i + 1) begin
                add_reg[i] <= xin_reg[i] + xin_reg[15-i];
            end
        end
    end

    wire [11:0] coe[7:0];
    assign coe[0] = 12'd11;
    assign coe[1] = 12'd31;
    assign coe[2] = 12'd63;
    assign coe[3] = 12'd104;
    assign coe[4] = 12'd152;
    assign coe[5] = 12'd198;
    assign coe[6] = 12'd235;
    assign coe[7] = 12'd255;

    reg [24:0] mout[7:0];
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 8; i = i + 1) begin
                mout[i] <= 25'b0;
            end
        end else if (en_r[1]) begin
            for (i = 0; i < 8; i = i + 1) begin
                mout[i] <= coe[i] * add_reg[i];
            end
        end
    end

    wire valid_mult7 = en_r[2];

    reg [3:0] valid_mult_r;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_mult_r <= 4'b0;
        end else begin
            valid_mult_r <= {valid_mult_r[2:0], valid_mult7};
        end
    end

    reg signed [28:0] sum;
    reg signed [28:0] yout_t;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sum    <= 29'd0;
            yout_t <= 29'd0;
        end else if (valid_mult7) begin
            sum    <= mout[0] + mout[1] + mout[2] + mout[3] + mout[4] + mout[5] + mout[6] + mout[7];
            yout_t <= sum;
        end
    end

    assign yout = yout_t;
    assign yout_valid = valid_mult_r[0];

endmodule