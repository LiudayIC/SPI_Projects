module tb_SPI ();
    logic i_clk_master, i_rst;
    logic i_clk_slave;
    logic [7:0] i_data_master;
    logic [7:0] i_data_slave;
    logic i_cpha,i_cpol;
    logic i_en;
    logic [1:0] state_master;
    logic [1:0] state_slave;
    logic MISO_m, MOSI_m, SCK_m, CS_m;
    logic i_clr_flg;
    logic [3:0] bits_m,bits_s;

SPI_master master_dut(
    .i_clk(i_clk_master),
    .i_rst(i_rst),
    .i_clr_flg(i_clr_flg),
    .i_data_master(i_data_master),
    .i_cpha(i_cpha),
    .i_cpol(i_cpol),
    .i_en(i_en),
    .i_MISO(MISO_m),
    .o_MOSI(MOSI_m),
    .o_SCK(SCK_m),
    .bits(bits_m),
    .o_CS(CS_m)
);

SPI_Slave slave_dut(
    .i_clk (i_clk_slave),
    .i_rst (i_rst),
    .slave_data(i_data_slave),
    .i_cpha(i_cpha),
    .i_cpol(i_cpol),
    .i_MOSI_s(MOSI_m),
    .i_CS_s(CS_m),
    .i_SCK_s(SCK_m),
    .bits(bits_s),
    .o_MISO_s(MISO_m)
);

always #5 i_clk_master <= ~i_clk_master;
always #3 i_clk_slave  <= ~i_clk_slave;

initial begin
    $shm_open("SPI.shm");
    $shm_probe("AS");
end

task enable;
 i_en = 1'b1;
 #10 i_en = 1'b0;
endtask

task reset; 
 i_rst = 1'b0;
 i_en = 1'b0;
 #3 i_rst = 1'b1;
endtask

task spi_mode0;
     i_data_master = 8'hFE;
     i_data_slave    = 8'h11;
     i_cpol        =  1'b0;
     i_cpha        =  1'b1;
    #10 i_en = 1'b1;
    #10 i_en = 1'b0;
endtask

task spi_mode1;
     i_data_master = 8'hAB;
     i_data_slave    = 8'hCD;
     i_cpol        =  1'b0;
     i_cpha        =  1'b0;
    #10 i_en = 1'b1;
    #10 i_en = 1'b0;
endtask

task spi_mode2;
     i_data_master = 8'hEF;
     i_data_slave    = 8'hF1;
     i_cpol        = 1'b1;
     i_cpha        = 1'b0;
    #10 i_en = 1'b1;
    #10 i_en = 1'b0;
endtask

task spi_mode3; 
     i_data_master = 8'h23;
     i_data_slave    = 8'h45;
     i_cpol        = 1'b1;
     i_cpha        = 1'b1;
    #10 i_en = 1'b1;
    #10 i_en = 1'b0;
endtask

task clk_gen;
     i_clk_master = 1'b0;
     i_clk_slave  = 1'b0;
endtask

initial begin
    clk_gen;
    reset;
    spi_mode0;
    #190 spi_mode1;
    #190 spi_mode2;
    #190 spi_mode3;
    #190 spi_mode0;
    #190  $finish;
end



endmodule
