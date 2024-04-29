`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 22.04.2024 15:56:43
// Design Name:
// Module Name: verilog
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module audio_top (
    input clk_100,                            // 100 MHz input clock from top level logic
    output AC_MCLK,                           // 24 MHz for ADAU1761
    output AC_ADR0,                           // I2C contol signals to ADAU1761, for configuration
    output AC_ADR1,
    output AC_SCK,
    inout AC_SDA,
    output AC_GPIO0,                         // I2S MISO
    input AC_GPIO1,                           // I2S MOSI
    input AC_GPIO2,                           // I2S_bclk
    input AC_GPIO3,                           // I2S_LR
    input [23:0] hphone_l,               // samples to headphone jack
    input hphone_l_valid,
    input [23:0] hphone_r,
    input hphone_r_valid_dummy,     // dummy valid signal to create AXIS interface in Vivado (r and l channel synchronous to hphone_l_valid
    output [23:0] line_in_l,               // samples from "line in" jack
    output [23:0] line_in_r,
    output new_sample,                      // active for 1 clk cycle if new "line in" sample is transmitted/received
    output sample_clk_48k              // sample clock (new sample at rising edge)
);

wire clk_48;                                          // Master clock (48 MHz) of the design
wire new_sample_100;                           // New samples signal in the 100 MHz domain
wire [23:0] line_in_l_freeze_48, line_in_r_freeze_48;   // "Line in" signals from I2S receiver to external interface (are frozen by the I2S receiver)
wire sample_clk_48k_d1_48, sample_clk_48k_d2_48, sample_clk_48k_d3_48;   // Delay and synchronization registers for the sample clock (48k)
wire sample_clk_48k_d4_100, sample_clk_48k_d5_100, sample_clk_48k_d6_100; // For CDC 100 -> 48 MHz freeze registers
wire [23:0] hphone_l_freeze_100, hphone_r_freeze_100;     // For CDC 100 -> 48 MHz freeze registers
wire hphone_valid;                            // Internal signal for hphone_l_valid

assign hphone_valid = hphone_l_valid;

clocking i_clocking (
    .CLK_100(clk_100),
    .CLK_48(clk_48),
    .RESET(1'b0),                           // No reset provided in VHDL code
    .LOCKED()
);

// ADAU1761 instance
adau1761_izedboard Inst_adau1761_izedboard (
    .clk_48(clk_48),
    .AC_ADR0(AC_ADR0),
    .AC_ADR1(AC_ADR1),
    .AC_GPIO0(AC_GPIO0),
    .AC_GPIO1(AC_GPIO1),
    .AC_GPIO2(AC_GPIO2),
    .AC_GPIO3(AC_GPIO3),
    .AC_MCLK(AC_MCLK),
    .AC_SCK(AC_SCK),
    .AC_SDA(AC_SDA),
    .hphone_l(hphone_l_freeze_100),
    .hphone_r(hphone_r_freeze_100),
    .line_in_l(line_in_l_freeze_48),
    .line_in_r(line_in_r_freeze_48),
    .new_sample(),                                // new_sample is generated in the correct clock domain
    .sw({2'b00}),                                  // All switches signals are tied to 0
    .active()
);

always @(posedge clk_48) begin
    // Shift sample clock for synchronization
    sample_clk_48k_d3_48 <= sample_clk_48k_d2_48;
    sample_clk_48k_d2_48 <= sample_clk_48k_d1_48;
    sample_clk_48k_d1_48 <= AC_GPIO3;
end

always @(posedge clk_100) begin
        sample_clk_48k_d4_100 <= sample_clk_48k_d3_48;  // ff1 & 2 for synchronization
        sample_clk_48k_d5_100 <= sample_clk_48k_d4_100;
        sample_clk_48k_d6_100 <= sample_clk_48k_d5_100; // ff3 for edge detection
        sample_clk_48k <= sample_clk_48k_d6_100;        // additional FF for signal delay (alignment to data)
       
        if (sample_clk_48k_d5_100 && !sample_clk_48k_d6_100) begin
            new_sample_100 <= 1'b1;
        end else begin
            new_sample_100 <= 1'b0;
        end
        new_sample <= new_sample_100;  // additional FF for signal delay (alignment to data)
end

// CDC for headphone audio data (l&r) 100 MHz -> 48 MHz
always @(posedge clk_100) begin
    if (hphone_valid)
        hphone_l_freeze_100 <= hphone_l;
        hphone_r_freeze_100 <= hphone_r;
end

// CDC for line_in audio data: 48 MHz -> 100 MHz
always @(posedge clk_100) begin
    if (new_sample_100)
        line_in_l <= line_in_l_freeze_48;
        line_in_r <= line_in_r_freeze_48;
end

endmodule
