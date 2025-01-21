module mult_shift_tb();

parameter N=13;
parameter M=12;

reg clk, rstn, en;
reg [N-1:0] mult1;
reg [M-1:0] mult2;

wire finish;
wire [N+M-1:0] result;


initial begin
    clk = 0; 
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    en =0 ;
    rstn = 0;
    #20 rstn = 1;
    en=1;
end

initial begin
    mult1 = 0;
    mult2 = 3;
    forever begin
        @(negedge clk);
        mult1 = mult1+1;
        mult2 = mult2+1;
    end
end


reg [N+M-1:0] res_com [0:M-1];
integer i;
initial begin
    for (i=0;i<M;i=i+1) begin
        res_com[i] = 0;
    end
    forever begin
        @(posedge clk);
        if (en) begin
            res_com[0] <= mult1 * mult2;
        end
        for (i=1 ;i<M ;i=i+1 ) begin
            res_com[i] <= res_com[i-1];            
        end
    end
end

wire acc;
assign acc = finish ? res_com[M-1]==result? 1 : 0 :0;

wire [N+M-1:0] aa;
assign aa = res_com[M-1];

initial begin
    $dumpfile("mult_shift_tb.vcd");
    $dumpvars();
end

initial begin
    #100000 $finish;
end

mult_man #(.N(N), .M(M))
u_mult_man
(
    .clk(clk),
    .rstn(rstn),
    .data_rdy(en),
    .mult1(mult1),
    .mult2(mult2),
    .res_rdy(finish),
    .res(result)
);



endmodule