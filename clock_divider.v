module clock_divider(
    input clk_50MHz,
    input reset,
    output reg clk_1Hz
);
    reg [25:0] counter;
    
    always @(posedge clk_50MHz or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_1Hz <= 0;
        end
        else begin
            if (counter == 25_000_000) begin
                counter <= 0;
                clk_1Hz <= ~clk_1Hz;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end
endmodule