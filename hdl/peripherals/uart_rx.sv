//-------------------------------------------------------------------------------------------------
// Jason Wilden 2025
//-------------------------------------------------------------------------------------------------
`default_nettype none

module uart_rx #(
  parameter DATA_WIDTH=8,                         // Data byte size
            SB_TICK=16,                           // Length of stop bit in ticks (1, 1.5 or 2 x 16)
            DIV=95                                // Tick generator divider 
)
(
  input var logic i_clk,        
  input var logic i_reset_n,
  input var logic i_rx,                           // Serial data in
  output logic o_ready,                           // Data ready for read
  output logic[7:0] o_data                        // Data
);

typedef enum                                      
{ 
  IDLE,                                           // Line idle
  START,                                          // Start bit received (RX pulled low)
  DATA,                                           // Receiving data
  STOP                                            // Waiting for stop bit
} state_t;

state_t state_ps, state_ns;                       // State registers
logic ready;                                      // Data ready
logic [3:0] ticks_ps, ticks_ns;                   // Tick count
logic [2:0] bits_ps, bits_ns;                     // Bits received count
logic [7:0] data_ps, data_ns;                     // Data byte
logic tick;                                       // Oversampling tick from generator


uart_tick_gen tg                                  // Sample tick generator instance
(
  .i_clk(i_clk),
  .i_reset_n(i_reset_n),
  .i_div(11'(DIV)),                     
  .o_tick(tick)
);

always_ff @(posedge i_clk, negedge i_reset_n) begin
  if(!i_reset_n) begin
    state_ps <= IDLE;                             // Starting state IDLE
    ticks_ps <= 4'b0;                             // Zero all counters
    bits_ps <= 3'b0;
    data_ps <= 8'b0;
  end else begin
    state_ps <= state_ns;                         // Move to next state
    ticks_ps <= ticks_ns;                         // Update counters
    bits_ps <= bits_ns;               
    data_ps <= data_ns;               
  end
end

// Next state logic
always_comb begin
  state_ns = state_ps;                            // Default all values to avoid latches
  ready = 1'b0;
  ticks_ns = ticks_ps;
  bits_ns =  bits_ps;
  data_ns = data_ps;

  case(state_ps)
    IDLE:
      if(~i_rx) begin                             // RX going low indicates a possible new data byte
        state_ns = START;                         // Move to START state
        ticks_ns = 0;                             // Reset tick count
      end
    START:
      if(tick) begin              
        if(ticks_ps == 7) begin                   // Wait 7 ticks before we start sampling data
          state_ns=DATA;                          // Move to DATA state to start sampling data line
          ticks_ns = 0;                           // Reset tick count
          bits_ns = 0;                            // Reset bits received count
        end else begin
          ticks_ns = 4'(ticks_ps + 1);
        end
      end
    DATA:
      if(tick) begin
        if(ticks_ps == 15) begin                  // Wait 16 ticks, this places us in middle of data bit
          ticks_ns = 0;                           // Reset ticks
          data_ns = 8'({i_rx, data_ps[7:1]});     // Shift serial data into register
          if(bits_ps == (DATA_WIDTH-1)) begin 
            state_ns = STOP;                      // Data word received, move to STOP stage
          end else begin
            bits_ns = 3'(bits_ps + 1);
          end
        end else begin
          ticks_ns = 4'(ticks_ps + 1);  
        end
      end
    STOP:
      if(tick) begin                        
        if(ticks_ps == SB_TICK -1) begin          // Wait until we we pass end of stop bit, this could be 1,1.5 or 2 bits
          state_ns = IDLE;                        // Back to IDLE
          ready = 1'b1;                           // Signal byte is ready 
        end else begin
          ticks_ns = 4'(ticks_ps + 1);
        end
      end
  endcase
end

                          
assign o_data = data_ps;                          // Outputs
assign o_ready = ready;

endmodule

