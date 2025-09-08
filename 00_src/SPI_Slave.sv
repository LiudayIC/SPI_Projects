module SPI_Slave(
    input  logic i_clk, i_rst, //FPGA global clock
    // input from control register

    input  logic i_cpol, i_cpha,

    //signal for debugg

    input  logic [7:0] slave_data,

    // output of SPI master -- input of SPI Slave

    input  logic i_MOSI_s,
    input  logic i_SCK_s,
    input  logic i_CS_s,    

    //output of SPI slave

    output logic o_MISO_s,
    output logic [3:0] bits
);

logic [7:0] buffer_reg_q, buffer_reg_d;
logic [7:0] RX_reg_d, RX_reg_q;     // Shift register
logic [3:0] counter_q;
logic [3:0] counter_d;   
logic       SPI_clk, full;
logic 	    SCK;
logic 	    stop;
logic 	    last_bit;
logic read,change;
logic [8:1] slave_reg_q, slave_reg_d;
logic test, pedge_CS, nedge_CS;

edgedetect sck_edge(
  .i_clk    (i_clk),
  .signal   (i_SCK_s),
  .trigger  (SCK)
);

nedge cs_negedge(
 .i_clk (i_clk),
 .signal (i_CS_s),
 .nedge (nedge_CS)
);

pedge cs_posedge(
 .i_clk (i_clk),
 .signal (i_CS_s),
 .pedge (pedge_CS)
);

logic ena,final_bit;
assign neg_cpha = nedge_CS | SCK;
assign pos_cpha = pedge_CS | SCK;
assign SPI_clk = ~i_cpha ? neg_cpha : pos_cpha;



typedef enum logic [1:0] {StIdle, StChange, StRead} my_state;
my_state current_state, next_state;

always_ff @ (posedge SPI_clk  or negedge i_rst) begin
 if (~i_rst | i_CS_s) begin  
  current_state <= StIdle;
  counter_q <= 3'd0;
  buffer_reg_q <= 7'd0;
 end else begin
  current_state <= next_state;
  counter_q <= counter_d;
  slave_reg_q <= slave_reg_d;
  buffer_reg_q <= buffer_reg_d;
end
end

always_comb begin
 next_state = current_state; 
  case (current_state)
   StIdle       : begin 
    if      (~i_CS_s)   next_state =  StChange;
    else                next_state =  StIdle;
   end
   StChange       : begin
    if         (~i_CS_s | ~last_bit)           next_state = StRead;
    else if       (i_CS_s | i_CS_s)         next_state = StIdle;
   end
   StRead : begin
    if       (last_bit | i_CS_s)        next_state = StIdle;
    else if  (~ i_CS_s | ~last_bit)         next_state = StChange; 
   end
 endcase  
end

assign buffer_reg_d = ~i_CS_s ? slave_data : buffer_reg_q;
assign last_bit = counter_d == 4'd8 ? 1'b1 : 1'b0;
assign RX_reg_q = buffer_reg_q;
logic buffer;
 
always_comb begin
 {change,read} = 2'b0;
 case (current_state) 
  StIdle : begin    //00
    counter_d = 4'd0;
    o_MISO_s  = 1'bZ;
  end
  StChange : begin    //10
    change = 1'b1;
    counter_d = counter_q + 1'b1;
     buffer = i_MOSI_s;
    o_MISO_s    =  RX_reg_q[counter_q];
  end 
  StRead : begin //01
    read  = 1'b1;
    slave_reg_d = {buffer,slave_reg_q[8:2]};
  end
 endcase 
end

assign bits = counter_d;
endmodule
