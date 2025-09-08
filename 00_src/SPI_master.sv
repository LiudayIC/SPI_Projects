module SPI_master(
    input  logic i_clk, i_rst,
    // input from data register

    input  logic [7:0] i_data_master, 

    // input from control register

    input  logic i_cpha, i_cpol,
    input  logic i_en,

    // input to clear FULL FLAG 

    input logic i_clr_flg,

    //output for debugg

    output logic [1:0] state,
    output logic       done,

    // input of SPI master
    input  logic i_MISO,

    //output of SPI master

    output logic o_MOSI,o_CS,
    output logic o_SCK,
    output logic [3:0] bits
);

typedef enum logic [1:0] {StIdle,StChange,StRead} my_state;
my_state current_state, next_state;

logic [7:0] buffer_reg_d, buffer_reg_q;
logic [7:0] master_reg_d,   master_reg_q;     // Change register
logic [3:0] counter_q, counter_d;
logic        full; 
logic        buffer_clk;
logic        stop;
logic        change,read;

always_ff @ (posedge i_clk or negedge i_rst) begin
 if (~i_rst) begin  
  current_state <= StIdle;
  master_reg_q   <= 7'd0;
  counter_q  <= 4'd0;
  buffer_reg_q <= 7'd0;
 end else begin
  current_state <= next_state;
  master_reg_q   <= master_reg_d;
  counter_q  <= counter_d;
  buffer_reg_q <= buffer_reg_d ;
 end
end


always_ff @(posedge i_clk or negedge i_rst or negedge o_CS) begin
  if (stop)       full <= 1'b1;
  else if (~o_CS | ~i_rst)            full <= 1'b0;
  else            full <= full;
end 



always_comb begin
 next_state = current_state; 
  case (current_state)
   StIdle       : begin //00
    if      (~o_CS & ~stop)  next_state =  StChange;
    else                     next_state =  StIdle;
   end
   StChange       : begin //01
    if (~stop & ~o_CS) next_state = StRead;
    else               next_state = StIdle;
   end
   StRead : begin //10
    if (stop  & ~o_CS)       next_state = StIdle;
    else                     next_state = StChange; 
   end
 endcase
end

assign buffer_reg_d = ~full ? i_data_master : buffer_reg_q;
assign stop = counter_q == 4'd8 ? 1'b1 : 1'b0;
logic MOSI_buffer;

always_comb begin
master_reg_d = master_reg_q;
{change,read} = 2'b0;
 case (current_state) 
  StIdle : begin    //00
    counter_d = 4'd0;
    master_reg_d = ~full ? buffer_reg_d : master_reg_q;
    o_MOSI = 1'bZ;
    o_SCK = i_cpol;
    o_CS = i_en ? 1'b0 : ~i_cpha ? ~stop : 1'b1;
  end
  StChange : begin    //01
   o_MOSI = master_reg_q[0];
    counter_d  =  counter_q + 1'b1;
    change = 1'b1;
    o_SCK = i_cpol ? ~i_cpha : i_cpha;
  end 
  StRead : begin //10
    master_reg_d  = {i_MISO,master_reg_q[7:1]};
    MOSI_buffer = master_reg_q[0];
    read = 1'b1;
    o_SCK = i_cpol ? i_cpha : ~i_cpha;
  end
 endcase
end

// MOSI and DEBUG signal
assign done = full;
assign state = current_state;

// CONFIGURE SPI CLOCK

assign bits = counter_d;
endmodule
