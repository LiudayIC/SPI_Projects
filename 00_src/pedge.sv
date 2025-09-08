module pedge(
 input logic i_clk,
 input logic signal,
 output logic pedge
);

logic reg_q, reg_d;

always_ff @(posedge i_clk) begin
 reg_q <= reg_d;
end

always_comb begin 
 reg_d =  signal;
 pedge =  ((signal == 1'b1) & (reg_q == 1'b0)) ? 1'b1 : 1'b0;
end

endmodule
