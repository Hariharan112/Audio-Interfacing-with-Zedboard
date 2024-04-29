// Entire module will change now
module clocking (
    input wire CLK_100,   // 100MHz input clock
    input wire RESET,     // Reset input
    output reg CLK_48,    // 48MHz output clock
    output reg LOCKED     // Locked output signal
);

reg [26:0] counter;  // 27-bit counter for dividing CLK_100
parameter COUNTER_MAX = 2083333;  // Value to divide CLK_100 to get 48MHz

always @(posedge CLK_100 or posedge RESET) begin
    if (RESET) begin
        counter <= 0;
        LOCKED <= 0;  // Reset LOCKED signal
    end else begin
        if (counter == COUNTER_MAX - 1) begin
            counter <= 0;  // Reset counter when reaching maximum count
            CLK_48 <= ~CLK_48;  // Toggle output clock to generate 48MHz
            LOCKED <= 1;  // Set LOCKED signal when clock is stable
        end else begin
            counter <= counter + 1;  // Increment counter
            LOCKED <= 0;  // Reset LOCKED signal while counting
        end
    end
end

endmodule
