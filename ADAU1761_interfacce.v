module ADAU1761_interface (
    input wire clk_48,
    output reg codec_master_clk
);


always @(posedge clk_48) begin
    codec_master_clk <= ~codec_master_clk;
end

endmodule
