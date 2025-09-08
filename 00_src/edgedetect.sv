module edgedetect(
    input  logic signal, i_clk,
    output logic trigger
);

logic reg1_d,reg1_q;

always_ff @ (posedge i_clk) begin
    reg1_q <= reg1_d; 
end

always_comb begin
    reg1_d  = signal;
    trigger  = signal ^ reg1_q;
end


endmodule
