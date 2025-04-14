module parking_slots(
    input clk_1Hz,
    input reset,
    input entry_sensor,
    input exit_sensor,
    input entry_button,
    input exit_button,
    input [3:0] token_input,
    output reg [3:0] total_slots,
    output reg [3:0] occupied_slots,
    output reg [3:0] remaining_slots,
    output reg entry_gate_open,
    output reg exit_gate_open,
    output reg [3:0] current_token
);

// Parameters
parameter TOTAL_CAPACITY = 4'd9;
parameter GATE_CLOSED = 1'b0;
parameter GATE_OPEN = 1'b1;

// LFSR for random token generation
reg [3:0] lfsr = 4'b0001;  // Initial seed (cannot be 0)
reg [3:0] stored_tokens [0:8];  // Store up to 9 tokens
reg token_valid;
integer i;  // Declare loop variable outside always blocks

// Debounced buttons
wire entry_button_db;
wire exit_button_db;

debounce db_entry(
    .clk_1Hz(clk_1Hz),
    .button_in(entry_button),
    .button_out(entry_button_db)
);

debounce db_exit(
    .clk_1Hz(clk_1Hz),
    .button_in(exit_button),
    .button_out(exit_button_db)
);

// Sensor edge detection
reg entry_sensor_prev;
reg exit_sensor_prev;

// Initialize values
initial begin
    total_slots = TOTAL_CAPACITY;
    occupied_slots = 4'd0;
    remaining_slots = TOTAL_CAPACITY;
    entry_gate_open = GATE_CLOSED;
    exit_gate_open = GATE_CLOSED;
    entry_sensor_prev = 1'b0;
    exit_sensor_prev = 1'b0;
    current_token = 4'd0;
    
    // Initialize all tokens as unused (0)
    for (i = 0; i < TOTAL_CAPACITY; i = i + 1) begin
        stored_tokens[i] = 4'd0;
    end
end

// =============================================
// 1. Token Generation and Management (LFSR)
// =============================================
always @(posedge clk_1Hz or posedge reset) begin
    if (reset) begin
        lfsr <= 4'b0001;  // Reset to initial seed
        current_token <= 4'd0;
    end
    else begin
        // LFSR random number generation (4-bit)
        lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[2]};
        
        // Ensure token is never 0 (0 means unused)
        if (lfsr == 4'd0) begin
            lfsr <= 4'b0001;
        end
    end
end

// =============================================
// 2. Entry Logic
// =============================================
always @(posedge clk_1Hz or posedge reset) begin
    if (reset) begin
        entry_gate_open <= GATE_CLOSED;
        entry_sensor_prev <= 1'b0;
    end
    else begin
        entry_sensor_prev <= entry_sensor;
        
        // Open entry gate if button pressed and space available
        if (entry_button_db && remaining_slots > 0 && !entry_gate_open) begin
            // Check if generated token is already in use
            token_valid = 1'b0;
            for (i = 0; i < TOTAL_CAPACITY; i = i + 1) begin
                if (stored_tokens[i] == lfsr) begin
                    token_valid = 1'b1;
                end
            end
            
            // If token is unique, use it
            if (!token_valid) begin
                entry_gate_open <= GATE_OPEN;
                current_token <= lfsr;
            end
        end
        
        // Detect car passing through (falling edge of sensor)
        if (entry_gate_open && !entry_sensor && entry_sensor_prev) begin
            entry_gate_open <= GATE_CLOSED;
            
            // Find first empty slot to store token
            for (i = 0; i < TOTAL_CAPACITY; i = i + 1) begin
                if (stored_tokens[i] == 4'd0) begin
                    stored_tokens[i] <= current_token;
                    occupied_slots <= occupied_slots + 1;
                    remaining_slots <= remaining_slots - 1;
                    current_token <= 4'd0;
                    break;
                end
            end
        end
    end
end

// =============================================
// 3. Exit Logic
// =============================================
always @(posedge clk_1Hz or posedge reset) begin
    if (reset) begin
        exit_gate_open <= GATE_CLOSED;
        exit_sensor_prev <= 1'b0;
    end
    else begin
        exit_sensor_prev <= exit_sensor;
        
        // Check token when exit button pressed
        if (exit_button_db && !exit_gate_open) begin
            token_valid = 1'b0;
            
            // Verify token exists in system
            for (i = 0; i < TOTAL_CAPACITY; i = i + 1) begin
                if (stored_tokens[i] == token_input && token_input != 4'd0) begin
                    token_valid = 1'b1;
                    stored_tokens[i] <= 4'd0;  // Mark as unused
                end
            end
            
            // Open gate if valid token
            if (token_valid) begin
                exit_gate_open <= GATE_OPEN;
            end
        end
        
        // Detect car leaving (falling edge of sensor)
        if (exit_gate_open && !exit_sensor && exit_sensor_prev) begin
            exit_gate_open <= GATE_CLOSED;
            if (occupied_slots > 0) begin
                occupied_slots <= occupied_slots - 1;
                remaining_slots <= remaining_slots + 1;
            end
        end
    end
end

// Keep total slots constant
always @(*) begin
    total_slots = TOTAL_CAPACITY;
end

endmodule