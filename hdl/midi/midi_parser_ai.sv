/*
  ------------------------------------------------------------------------------
   MIDI Parser - SystemVerilog Implementation
   Migrated from C implementation by ydigikat
  ------------------------------------------------------------------------------
   MIT License
   Copyright (c) 2025 YDigiKat
  ------------------------------------------------------------------------------
*/

module midi_parser #(
    parameter BUFFER_SIZE = 256,
    parameter BUFFER_ADDR_WIDTH = $clog2(BUFFER_SIZE)
)(
    input  logic        clk,
    input  logic        rst_n,
    
    // MIDI input interface
    input  logic        midi_byte_valid,
    input  logic [7:0]  midi_byte_data,
    output logic        midi_byte_ready,
    
    // Parsed message output
    output logic        msg_valid,
    output logic [7:0]  msg_data[3],
    output logic [1:0]  msg_len,
    input  logic        msg_ready,
    
    // Real-time message output (out-of-band)
    output logic        rt_msg_valid,
    output logic [7:0]  rt_msg_code,
    input  logic        rt_msg_ready,
    
    // Configuration
    input  logic [3:0]  channel,        // 0 = OMNI, 1-16 = specific channel
    input  logic        channel_filter_en
);

// MIDI Status Byte Definitions
localparam [7:0] MIDI_STATUS_NOTE_OFF       = 8'h80;
localparam [7:0] MIDI_STATUS_NOTE_ON        = 8'h90;
localparam [7:0] MIDI_STATUS_POLY_PRESSURE  = 8'hA0;
localparam [7:0] MIDI_STATUS_CONTROL_CHANGE = 8'hB0;
localparam [7:0] MIDI_STATUS_PROGRAM_CHANGE = 8'hC0;
localparam [7:0] MIDI_STATUS_CHANNEL_PRESSURE = 8'hD0;
localparam [7:0] MIDI_STATUS_PITCH_BEND     = 8'hE0;
localparam [7:0] MIDI_STATUS_SYS_EX_START   = 8'hF0;
localparam [7:0] MIDI_STATUS_TIME_CODE      = 8'hF1;
localparam [7:0] MIDI_STATUS_SONG_POS       = 8'hF2;
localparam [7:0] MIDI_STATUS_SONG_SELECT    = 8'hF3;
localparam [7:0] MIDI_STATUS_SYS_EX_END     = 8'hF7;
localparam [7:0] MIDI_STATUS_TIMING_CLOCK   = 8'hF8;
localparam [7:0] MIDI_STATUS_START          = 8'hFA;
localparam [7:0] MIDI_STATUS_CONTINUE       = 8'hFB;
localparam [7:0] MIDI_STATUS_STOP           = 8'hFC;
localparam [7:0] MIDI_STATUS_ACTIVE_SENSING = 8'hFE;
localparam [7:0] MIDI_STATUS_RESET          = 8'hFF;
localparam [7:0] MIDI_STATUS_INVALID        = 8'h00;

// State definitions
typedef enum logic [2:0] {
    IDLE,
    WAIT_DATA1,
    WAIT_DATA2,
    MSG_COMPLETE,
    SYSEX_ACTIVE
} midi_state_t;

// Current and next state
midi_state_t current_state, next_state;

// Parser state registers
logic [7:0] running_status, next_running_status;
logic       sysex_active, next_sysex_active;
logic [7:0] msg_buffer[3], next_msg_buffer[3];
logic [1:0] msg_length, next_msg_length;

// Ring buffer for incoming MIDI bytes
logic [7:0] ring_buffer[BUFFER_SIZE];
logic [BUFFER_ADDR_WIDTH-1:0] head_ptr, tail_ptr;
logic [BUFFER_ADDR_WIDTH-1:0] next_head_ptr, next_tail_ptr;
logic buffer_empty, buffer_full;
logic [7:0] buffer_data;
logic buffer_read_en;

// Internal signals
logic [7:0] current_byte;
logic byte_available;
logic is_status_byte, is_realtime, is_single_byte_msg;
logic channel_match;
logic process_byte;

// Real-time message detection (out-of-band)
logic is_rt_message;
logic rt_msg_valid_int;

// Byte classification
assign is_status_byte = current_byte[7];
assign is_single_byte_msg = (current_byte[7:2] == 6'b111101);

// Real-time message detection - specific codes only (excludes active sensing)
assign is_rt_message = (current_byte == MIDI_STATUS_TIMING_CLOCK) ||
                      (current_byte == MIDI_STATUS_START) ||
                      (current_byte == MIDI_STATUS_CONTINUE) ||
                      (current_byte == MIDI_STATUS_STOP) ||
                      (current_byte == MIDI_STATUS_RESET);

// Channel filtering
assign channel_match = !channel_filter_en || 
                      (channel == 4'h0) || 
                      ((current_byte[3:0] + 1) == channel);

// Buffer management
assign buffer_empty = (head_ptr == tail_ptr);
assign buffer_full = ((head_ptr + 1) % BUFFER_SIZE) == tail_ptr;
assign midi_byte_ready = !buffer_full;
assign byte_available = !buffer_empty;
assign buffer_data = ring_buffer[tail_ptr];

// Sequential logic - state and registers
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
        running_status <= MIDI_STATUS_INVALID;
        sysex_active <= 1'b0;
        msg_buffer[0] <= 8'h00;
        msg_buffer[1] <= 8'h00;
        msg_buffer[2] <= 8'h00;
        msg_length <= 2'h0;
        head_ptr <= '0;
        tail_ptr <= '0;
    end else begin
        current_state <= next_state;
        running_status <= next_running_status;
        sysex_active <= next_sysex_active;
        msg_buffer <= next_msg_buffer;
        msg_length <= next_msg_length;
        head_ptr <= next_head_ptr;
        tail_ptr <= next_tail_ptr;
    end
end

// Ring buffer write
always_ff @(posedge clk) begin
    if (midi_byte_valid && midi_byte_ready) begin
        ring_buffer[head_ptr] <= midi_byte_data;
    end
end

// Buffer pointer management
always_comb begin
    next_head_ptr = head_ptr;
    next_tail_ptr = tail_ptr;
    
    if (midi_byte_valid && midi_byte_ready) begin
        next_head_ptr = (head_ptr + 1) % BUFFER_SIZE;
    end
    
    if (buffer_read_en) begin
        next_tail_ptr = (tail_ptr + 1) % BUFFER_SIZE;
    end
end

// Current byte and read control
assign current_byte = buffer_data;
assign process_byte = byte_available && (msg_ready || !msg_valid) && (rt_msg_ready || !rt_msg_valid_int);

// Real-time message processing (out-of-band)
assign rt_msg_valid_int = process_byte && is_rt_message;
assign rt_msg_code = current_byte;
assign rt_msg_valid = rt_msg_valid_int;

// Buffer read enable - consume byte for either real-time or regular message processing
assign buffer_read_en = process_byte && (is_rt_message || 
                                        (next_state != current_state || 
                                         current_state == MSG_COMPLETE));

// Main state machine - combinatorial next state logic
always_comb begin
    // Default assignments
    next_state = current_state;
    next_running_status = running_status;
    next_sysex_active = sysex_active;
    next_msg_buffer = msg_buffer;
    next_msg_length = msg_length;
    
    // Only process non-real-time messages in state machine
    if (process_byte && !is_rt_message) begin
        // Handle SysEx
        if (sysex_active) begin
            if (current_byte == MIDI_STATUS_SYS_EX_END) begin
                next_sysex_active = 1'b0;
                next_state = IDLE;
            end
            // Stay in sysex, consume bytes without processing
        end
        // Process regular MIDI messages
        else begin
            case (current_state)
                IDLE: begin
                    if (is_status_byte) begin
                        next_running_status = current_byte;
                        
                        if (current_byte == MIDI_STATUS_SYS_EX_START) begin
                            next_sysex_active = 1'b1;
                        end
                        else if (is_single_byte_msg) begin
                            next_msg_buffer[0] = current_byte;
                            next_msg_buffer[1] = 8'h00;
                            next_msg_buffer[2] = 8'h00;
                            next_msg_length = 2'h1;
                            next_state = MSG_COMPLETE;
                        end
                        else begin
                            next_state = WAIT_DATA1;
                        end
                    end
                    else if (running_status != MIDI_STATUS_INVALID) begin
                        // Running status - treat as first data byte
                        if (channel_match || !channel_filter_en) begin
                            next_msg_buffer[0] = running_status;
                            next_msg_buffer[1] = current_byte;
                            
                            case (running_status[7:4])
                                4'h8, 4'h9, 4'hA, 4'hB, 4'hE: begin // Two-byte messages
                                    next_msg_length = 2'h2;
                                    next_state = WAIT_DATA2;
                                end
                                4'hC, 4'hD: begin // One data byte messages
                                    next_msg_length = 2'h2;
                                    next_state = MSG_COMPLETE;
                                end
                                default: begin
                                    next_state = IDLE;
                                end
                            endcase
                        end
                    end
                end
                
                WAIT_DATA1: begin
                    if (is_status_byte) begin
                        // New status byte, reset parser
                        next_running_status = current_byte;
                        if (current_byte == MIDI_STATUS_SYS_EX_START) begin
                            next_sysex_active = 1'b1;
                            next_state = IDLE;
                        end
                        else if (is_single_byte_msg) begin
                            next_msg_buffer[0] = current_byte;
                            next_msg_buffer[1] = 8'h00;
                            next_msg_buffer[2] = 8'h00;
                            next_msg_length = 2'h1;
                            next_state = MSG_COMPLETE;
                        end
                        else begin
                            next_state = WAIT_DATA1;
                        end
                    end
                    else if (channel_match || !channel_filter_en) begin
                        next_msg_buffer[0] = running_status;
                        next_msg_buffer[1] = current_byte;
                        
                        case (running_status[7:4])
                            4'h8, 4'h9, 4'hA, 4'hB, 4'hE: begin // Two-byte messages
                                next_msg_length = 2'h2;
                                next_state = WAIT_DATA2;
                            end
                            4'hC, 4'hD: begin // One data byte messages
                                next_msg_length = 2'h2;
                                next_state = MSG_COMPLETE;
                            end
                            default: begin
                                case (running_status)
                                    MIDI_STATUS_SONG_POS: begin
                                        next_msg_length = 2'h2;
                                        next_state = WAIT_DATA2;
                                        next_running_status = MIDI_STATUS_INVALID;
                                    end
                                    MIDI_STATUS_SONG_SELECT,
                                    MIDI_STATUS_TIME_CODE: begin
                                        next_msg_length = 2'h2;
                                        next_state = MSG_COMPLETE;
                                        next_running_status = MIDI_STATUS_INVALID;
                                    end
                                    default: begin
                                        next_state = IDLE;
                                        next_running_status = MIDI_STATUS_INVALID;
                                    end
                                endcase
                            end
                        endcase
                    end else begin
                        next_state = IDLE;
                    end
                end
                
                WAIT_DATA2: begin
                    if (is_status_byte) begin
                        // New status byte, reset parser
                        next_running_status = current_byte;
                        if (current_byte == MIDI_STATUS_SYS_EX_START) begin
                            next_sysex_active = 1'b1;
                            next_state = IDLE;
                        end
                        else if (is_single_byte_msg) begin
                            next_msg_buffer[0] = current_byte;
                            next_msg_buffer[1] = 8'h00;
                            next_msg_buffer[2] = 8'h00;
                            next_msg_length = 2'h1;
                            next_state = MSG_COMPLETE;
                        end
                        else begin
                            next_state = WAIT_DATA1;
                        end
                    end
                    else begin
                        next_msg_buffer[2] = current_byte;
                        next_msg_length = 2'h3;
                        next_state = MSG_COMPLETE;
                    end
                end
                
                MSG_COMPLETE: begin
                    next_state = IDLE;
                end
                
                default: begin
                    next_state = IDLE;
                end
            endcase
        end
    end
end

// Output assignments
assign msg_valid = (current_state == MSG_COMPLETE);
assign msg_data = msg_buffer;
assign msg_len = msg_length;

endmodule