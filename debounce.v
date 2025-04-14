module debounce(
    input clk_1Hz,       // 1Hz clock input
    input button_in,     // Active-low button input
    output reg button_out // Active-low debounced output
);

parameter MAX_COUNT = 3; // Debounce duration in clock cycles (3 seconds at 1Hz)
reg [1:0] counter = 0;
reg btn_stable = 1'b1;  // Default to not pressed (active-high)

always @(posedge clk_1Hz) begin
    if (button_in == 1'b0) begin  // Button is pressed (active-low)
        if (counter < MAX_COUNT) begin
            counter <= counter + 1;
        end
        else begin
            btn_stable <= 1'b1;  // Stable pressed state (active-low)
        end
    end
    else begin  // Button is released
        counter <= 0;
        btn_stable <= 1'b0;  // Stable released state
    end
    
    button_out <= btn_stable; // Output the debounced signal
end

endmodule