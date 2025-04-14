module top_park(
    input clk_50MHz,
    input reset,
    input [4:0] token_input,  // 5-bit token input from switches
    input entry_sensor,
    input exit_sensor,
    input entry_btn_raw,      // Raw button input
    input exit_btn_raw,       // Raw button input
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,  // 7-segment displays
    output [3:0] state,       // Current state
    output [4:0] token_code   // Generated token
);

// Internal signals
wire clk_1Hz;
wire entry_btn_db;
wire exit_btn_db;

// Clock divider instance
clock_divider clk_div (
    .clk_50MHz(clk_50MHz),
    .reset(reset),
    .clk_1Hz(clk_1Hz)
);

// Button debouncers
debounce db_entry (
    .clk_1Hz(clk_50MHz),
    .button_in(entry_btn_raw),
    .button_out(entry_btn_db)
);

debounce db_exit (
    .clk_1Hz(clk_50MHz),
    .button_in(exit_btn_raw),
    .button_out(exit_btn_db)
);

// Main parking FSM
parking_fsm parking_system (
    .clk(clk_1Hz),
    .reset(reset),
    .token_input(token_input),
    .entry_sensor(~entry_sensor),
    .exit_sensor(~exit_sensor),
    .entry_btn(entry_btn_db),
    .exit_btn(exit_btn_db),
    .HEX0(HEX0),
    .HEX1(HEX1),
    .HEX2(HEX2),
    .HEX3(HEX3),
    .HEX4(HEX4),
    .HEX5(HEX5),
    .state(state),
    .token_code(token_code)
);

endmodule