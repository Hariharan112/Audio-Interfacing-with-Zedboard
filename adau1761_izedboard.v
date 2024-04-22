module adau1761_izedboard (
    input wire clk_48,
    output reg AC_ADR0,
    output reg AC_ADR1,
    output reg AC_GPIO0,
    input wire AC_GPIO1,
    input wire AC_GPIO2,
    input wire AC_GPIO3,
    output reg AC_MCLK,
    output reg AC_SCK,
    inout wire AC_SDA,
    input wire [23:0] hphone_l,
    input wire [23:0] hphone_r,
    output reg [23:0] line_in_l,
    output reg [23:0] line_in_r,
    output reg new_sample,
    input wire [1:0] sw,
    output reg [1:0] active
);

reg codec_master_clk;
reg i2c_scl;
wire i2c_sda_i, i2c_sda_o, i2c_sda_t;
wire i2s_bclk, i2s_lr;
wire i2s_MOSI, i2s_MISO;

// Initialize ADDR0 and ADDR1
initial begin
    AC_ADR0 = 1'b1;
    AC_ADR1 = 1'b1;
end

// Connection assignments
assign AC_GPIO0 = i2s_MISO;
assign i2s_MOSI = AC_GPIO1;
assign i2s_bclk = AC_GPIO2;
assign i2s_lr = AC_GPIO3;
assign AC_MCLK = codec_master_clk;
assign AC_SCK = i2c_scl;

// IOBUF for bidirectional SDA
IOBUF IOBUF_inst (
   .O(i2c_sda_i),     // Buffer output
   .IO(AC_SDA),   // Buffer inout port (connect directly to top-level port)
   .I(i2c_sda_o),     // Buffer input
   .T(i2c_sda_t)      // 3-state enable input, high=input, low=output
);

// Instantiate components
i2c Inst_i2c (
    .clk(clk_48),
    .i2c_sda_i(i2c_sda_i),
    .i2c_sda_o(i2c_sda_o),
    .i2c_sda_t(i2c_sda_t),
    .i2c_scl(i2c_scl),
    .sw(sw),
    .active(active)
);

ADAU1761_interface i_ADAU1761_interface (
    .clk_48(clk_48),
    .codec_master_clk(codec_master_clk)
);

i2s_data_interface Inst_i2s_data_interface (
    .clk(clk_48),
    .audio_l_out(line_in_l),
    .audio_r_out(line_in_r),
    .audio_l_in(hphone_l),
    .audio_r_in(hphone_r),
    .new_sample(new_sample),
    .i2s_bclk(i2s_bclk),
    .i2s_d_out(i2s_MISO),
    .i2s_d_in(i2s_MOSI),
    .i2s_lr(i2s_lr)
);

endmodule
