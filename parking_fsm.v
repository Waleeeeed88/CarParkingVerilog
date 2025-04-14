module parking_fsm(
    input clk,
    input reset,
    input [4:0] token_input,  // 5-bit token input from switches
    input entry_sensor,
    input exit_sensor,
    input entry_btn,
    input exit_btn,
    output reg [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,  // 7-segment displays
    output reg [3:0] state,     // Current state
    output reg [4:0] token_code  // Generated token
);

// Parameters for states
parameter WAIT        = 4'b0000;
parameter ENTRY       = 4'b0001;
parameter TOKEN_STATE = 4'b0010;
parameter OPEN_ENTRY  = 4'b0011;
parameter CLOSE_ENTRY = 4'b0100;
parameter EXIT        = 4'b0101;
parameter OPEN_EXIT   = 4'b0110;
parameter CLOSE_EXIT  = 4'b0111;
parameter ERROR_CODE  = 4'b1000;

// Parking slot counters
reg [4:0] slots_available = 5'd9;  // Assuming 9 total slots
reg [4:0] slots_used = 5'd0;
reg [4:0] total_slots = 5'd9;

// Timer for state delays
reg [2:0] timer_count = 3'd0;

// LFSR for token generation
reg [4:0] lfsr = 5'b00001;
reg [4:0] stored_tokens [0:8];  // Store up to 9 tokens
reg token_valid;
reg [2:0] token_attempts = 0;  // Counter for token generation attempts

// Seven-segment display encodings (active low)
parameter S_0 = 7'b1000000;  // '0'
parameter S_1 = 7'b1111001;  // '1'
parameter S_2 = 7'b0100100;  // '2'
parameter S_3 = 7'b0110000;  // '3'
parameter S_4 = 7'b0011001;  // '4'
parameter S_5 = 7'b0010010;  // '5'
parameter S_6 = 7'b0000010;  // '6'
parameter S_7 = 7'b1111000;  // '7'
parameter S_8 = 7'b0000000;  // '8'
parameter S_9 = 7'b0010000;  // '9'
parameter S_P = 7'b0001100;  // 'P'
parameter S_R = 7'b0101111;  // 'R'
parameter S_E = 7'b0000110;  // 'E'
parameter S_S = 7'b0010010;  // 'S'
parameter S_O = 7'b1000000;  // 'O' (same as 0)
parameter S_N = 7'b0101011;  // 'N'
parameter S_C = 7'b1000110;  // 'C'
parameter S_L = 7'b1000111;  // 'L'
parameter S_A = 7'b0001000;  // 'A'
parameter S_D = 7'b0100001;  // 'D'
parameter S_U = 7'b1000001;  // 'U'
parameter S_T = 7'b0000111;  // 'T'
parameter S_BLANK = 7'b1111111; // Blank

// Initialize token storage
integer i;
initial begin
    for (i = 0; i < 9; i = i + 1) begin
        stored_tokens[i] = 5'b00000;  // Initialize all tokens as unused
    end
end

// State transition logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= WAIT;
        timer_count <= 3'd0;
        slots_available <= 5'd9;
        slots_used <= 5'd0;
        lfsr <= 5'b00001;
        token_code <= 5'b00001;
        token_attempts <= 0;
    end
    else begin
        case (state)
            WAIT: begin
                timer_count <= 3'd0;
                token_attempts <= 0;
                if (entry_sensor && (slots_available > 0)) begin
                    state <= ENTRY;
                end
                else if (exit_sensor && (slots_used > 0)) begin
                    state <= EXIT;
                end
            end
            
            ENTRY: begin
                if (!entry_sensor) begin
                    state <= WAIT;
                end
                else if (entry_btn) begin
					 // Generate new token using LFSR
                lfsr <= {lfsr[3:0], lfsr[4] ^ lfsr[2]};
                if (lfsr == 5'b00000) lfsr <= 5'b00001;  // Ensure not zero
                    state <= TOKEN_STATE;
                end
            end
            
            TOKEN_STATE: begin
                
                
                // Check if token is unique
                token_valid = 1'b1;
                
                if (stored_tokens[0] == lfsr) token_valid = 1'b0;
                if (stored_tokens[1] == lfsr) token_valid = 1'b0;
                if (stored_tokens[2] == lfsr) token_valid = 1'b0;
                if (stored_tokens[3] == lfsr) token_valid = 1'b0;
                if (stored_tokens[4] == lfsr) token_valid = 1'b0;
                if (stored_tokens[5] == lfsr) token_valid = 1'b0;
                if (stored_tokens[6] == lfsr) token_valid = 1'b0;
                if (stored_tokens[7] == lfsr) token_valid = 1'b0;
                if (stored_tokens[8] == lfsr) token_valid = 1'b0;
                
                if (token_valid) begin
                    token_code <= lfsr;
                    if (timer_count < 3'd2) begin
                        timer_count <= timer_count + 1;
                    end
                    else begin
                        timer_count <= 3'd0;
                        state <= OPEN_ENTRY;
                    end
                end
                else if (token_attempts > 3'd7) begin
                    // Fallback if can't generate valid token
                    state <= ERROR_CODE;
                    token_attempts <= 0;
                end
                else begin
                    token_attempts <= token_attempts + 1;
                end
            end
            
            OPEN_ENTRY: begin
                if (timer_count < 3'd5) begin
                    timer_count <= timer_count + 1;
                end
                else begin
                    timer_count <= 3'd0;
                    state <= CLOSE_ENTRY;
                end
            end
            
            CLOSE_ENTRY: begin
                if (timer_count < 3'd5) begin
                    timer_count <= timer_count + 1;
                end
                else begin
                    timer_count <= 3'd0;
                    // Update counters and store token
                    slots_available <= slots_available - 1;
                    slots_used <= slots_used + 1;
                    
                    // Store token in first available slot
                    if (stored_tokens[0] == 5'b00000) stored_tokens[0] <= token_code;
                    else if (stored_tokens[1] == 5'b00000) stored_tokens[1] <= token_code;
                    else if (stored_tokens[2] == 5'b00000) stored_tokens[2] <= token_code;
                    else if (stored_tokens[3] == 5'b00000) stored_tokens[3] <= token_code;
                    else if (stored_tokens[4] == 5'b00000) stored_tokens[4] <= token_code;
                    else if (stored_tokens[5] == 5'b00000) stored_tokens[5] <= token_code;
                    else if (stored_tokens[6] == 5'b00000) stored_tokens[6] <= token_code;
                    else if (stored_tokens[7] == 5'b00000) stored_tokens[7] <= token_code;
                    else if (stored_tokens[8] == 5'b00000) stored_tokens[8] <= token_code;
                    
                    state <= WAIT;
                end
            end
            
            EXIT: begin
                timer_count <= 3'd0;
                if (exit_btn && exit_sensor) begin
                    // Check if token exists in system
                    token_valid = 1'b0;
                    
                    if (stored_tokens[0] == token_input && token_input != 5'b00000) begin
                        token_valid = 1'b1;
                        stored_tokens[0] <= 5'b00000;
                    end
                    else if (stored_tokens[1] == token_input && token_input != 5'b00000) begin
                        token_valid = 1'b1;
                        stored_tokens[1] <= 5'b00000;
                    end
                    else if (stored_tokens[2] == token_input && token_input != 5'b00000) begin
                        token_valid = 1'b1;
                        stored_tokens[2] <= 5'b00000;
                    end
                    else if (stored_tokens[3] == token_input && token_input != 5'b00000) begin
                        token_valid = 1'b1;
                        stored_tokens[3] <= 5'b00000;
                    end
                    else if (stored_tokens[4] == token_input && token_input != 5'b00000) begin
                        token_valid = 1'b1;
                        stored_tokens[4] <= 5'b00000;
                    end
                    else if (stored_tokens[5] == token_input && token_input != 5'b00000) begin
                        token_valid = 1'b1;
                        stored_tokens[5] <= 5'b00000;
                    end
                    else if (stored_tokens[6] == token_input && token_input != 5'b00000) begin
                        token_valid = 1'b1;
                        stored_tokens[6] <= 5'b00000;
                    end
                    else if (stored_tokens[7] == token_input && token_input != 5'b00000) begin
                        token_valid = 1'b1;
                        stored_tokens[7] <= 5'b00000;
                    end
                    else if (stored_tokens[8] == token_input && token_input != 5'b00000) begin
                        token_valid = 1'b1;
                        stored_tokens[8] <= 5'b00000;
                    end
                    
                    if (token_valid) begin
                        state <= OPEN_EXIT;
                    end
                    else begin
                        state <= ERROR_CODE;
                    end
                end
                else if (!exit_sensor) begin
                    state <= WAIT;
                end
            end
            
            OPEN_EXIT: begin
                if (timer_count < 3'd5) begin
                    timer_count <= timer_count + 1;
                end
                else begin
                    timer_count <= 3'd0;
                    state <= CLOSE_EXIT;
                end
            end
            
            CLOSE_EXIT: begin
                if (timer_count < 3'd5) begin
                    timer_count <= timer_count + 1;
                end
                else begin
                    timer_count <= 3'd0;
                    // Update counters
                    slots_available <= slots_available + 1;
                    slots_used <= slots_used - 1;
                    state <= WAIT;
                end
            end
            
            ERROR_CODE: begin
                if (timer_count < 3'd3) begin
                    timer_count <= timer_count + 1;
                end
                else begin
                    timer_count <= 3'd0;
                    state <= WAIT;
                end
            end
            
            default: state <= WAIT;
        endcase
    end
end

// Seven-segment display logic
always @(*) begin
    case (state)
        WAIT: begin
            // Show parking status
            HEX0 = (slots_used == 0) ? S_0 : 
                  (slots_used == 1) ? S_1 :
                  (slots_used == 2) ? S_2 :
                  (slots_used == 3) ? S_3 :
                  (slots_used == 4) ? S_4 :
                  (slots_used == 5) ? S_5 :
                  (slots_used == 6) ? S_6 :
                  (slots_used == 7) ? S_7 :
                  (slots_used == 8) ? S_8 : S_9;
            
            HEX1 = S_BLANK;
            
            HEX2 = (slots_available == 0) ? S_0 : 
                  (slots_available == 1) ? S_1 :
                  (slots_available == 2) ? S_2 :
                  (slots_available == 3) ? S_3 :
                  (slots_available == 4) ? S_4 :
                  (slots_available == 5) ? S_5 :
                  (slots_available == 6) ? S_6 :
                  (slots_available == 7) ? S_7 :
                  (slots_available == 8) ? S_8 : S_9;
            
            HEX3 = S_BLANK;
            HEX4 = S_BLANK;
            
            HEX5 = (total_slots == 0) ? S_0 : 
                  (total_slots == 1) ? S_1 :
                  (total_slots == 2) ? S_2 :
                  (total_slots == 3) ? S_3 :
                  (total_slots == 4) ? S_4 :
                  (total_slots == 5) ? S_5 :
                  (total_slots == 6) ? S_6 :
                  (total_slots == 7) ? S_7 :
                  (total_slots == 8) ? S_8 : S_9;
        end
        
        ENTRY: begin
            // Display "PRESS"
            HEX5 = S_P;
            HEX4 = S_R;
            HEX3 = S_E;
            HEX2 = S_S;
            HEX1 = S_S;
            HEX0 = S_BLANK;
        end
        
        TOKEN_STATE: begin
            // Display token code on HEX0-HEX4 (5 digits)
            HEX0 = (token_code[0]) ? S_1 : S_0;
            HEX1 = (token_code[1]) ? S_1 : S_0;
            HEX2 = (token_code[2]) ? S_1 : S_0;
            HEX3 = (token_code[3]) ? S_1 : S_0;
            HEX4 = (token_code[4]) ? S_1 : S_0;
            HEX5 = S_BLANK;
        end
        
        OPEN_ENTRY: begin
            // Display "OPEN1"
            HEX5 = S_O;
            HEX4 = S_P;
            HEX3 = S_E;
            HEX2 = S_N;
            HEX1 = S_1;
            HEX0 = S_BLANK;
        end
        
        CLOSE_ENTRY: begin
            // Display "CLOSE"
            HEX5 = S_C;
            HEX4 = S_L;
            HEX3 = S_O;
            HEX2 = S_S;
            HEX1 = S_E;
            HEX0 = S_BLANK;
        end
        
        EXIT: begin
            // Display "ENTER"
            HEX5 = S_E;
            HEX4 = S_N;
            HEX3 = S_T;
            HEX2 = S_E;
            HEX1 = S_R;
            HEX0 = S_BLANK;
        end
        
        OPEN_EXIT: begin
            // Display "OPEN2"
            HEX5 = S_O;
            HEX4 = S_P;
            HEX3 = S_E;
            HEX2 = S_N;
            HEX1 = S_2;
            HEX0 = S_BLANK;
        end
        
        CLOSE_EXIT: begin
            // Display "CLOSE"
            HEX5 = S_C;
            HEX4 = S_L;
            HEX3 = S_O;
            HEX2 = S_S;
            HEX1 = S_E;
            HEX0 = S_BLANK;
        end
        
        ERROR_CODE: begin
            // Display "ERROR"
            HEX5 = S_E;
            HEX4 = S_R;
            HEX3 = S_R;
            HEX2 = S_O;
            HEX1 = S_R;
            HEX0 = S_BLANK;
        end
        
        default: begin
            HEX0 = S_BLANK;
            HEX1 = S_BLANK;
            HEX2 = S_BLANK;
            HEX3 = S_BLANK;
            HEX4 = S_BLANK;
            HEX5 = S_BLANK;
        end
    endcase
end

endmodule