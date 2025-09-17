//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none

module uart_rx #(
  parameter DATA_WIDTH=8,     // Data byte size
            SB_TICK=16,       // Stop bit position             
            DIV=16            // Tick generator divider 
)
(
  input var logic i_clk,
  input var logic i_reset_n,
  input var logic i_rx,
  output logic o_ready,
  output logic[7:0] o_data
);

// States
typedef enum 
{ 
  IDLE,
  START,
  DATA,
  STOP
} state_t;

// Registers
state_t state_ps, state_ns;             // State registers
logic ready;                            // Data ready
logic [3:0] ticks_ps, ticks_ns;           // Tick count
logic [2:0] bits_ps, bits_ns;           // Bits received count
logic [7:0] data_ps, data_ns;           // Data byte
logic tick;                             // Oversampling tick from generator

// Tick generator
uart_tick_gen tg
(
  .i_clk(i_clk),
  .i_reset_n(i_reset_n),
  .i_div(11'(DIV)),
  .o_tick(tick)
);

// State machine registers
always_ff @(posedge i_clk, negedge i_reset_n) begin
  if(!i_reset_n) begin
    state_ps <= IDLE;
    ticks_ps <= 4'b0;
    bits_ps <= 3'b0;
    data_ps <= 8'b0;
  end else begin
    state_ps <= state_ns;
    ticks_ps <= ticks_ns;
    bits_ps <= bits_ns;
    data_ps <= data_ns;
  end
end

// Next state logic
always_comb begin
  state_ns = state_ps;
  ready = 1'b0;
  ticks_ns = ticks_ps;
  bits_ns =  bits_ps;
  data_ns = data_ps;

  case(state_ps)
    IDLE:
      if(~i_rx) begin             // RX going low indicates a possible new data byte
        state_ns = START;
        ticks_ns = 0;
      end
    START:
      if(tick) begin            // Wait 7 ticks before we start sampling data
        if(ticks_ps == 7) begin
          state_ns=DATA;          // Sample data line
          ticks_ns = 0;
          bits_ns = 0;
        end else begin
          ticks_ns = 4'(ticks_ps + 1);
        end
      end
    DATA:
      if(tick) begin
        if(ticks_ps == 15) begin             // 16 bits 
          ticks_ns = 0;
          data_ns = 8'({i_rx, data_ps[7:1]});   // Shift data into register
          if(bits_ps == (DATA_WIDTH-1)) begin
            state_ns = STOP;
          end else begin
            bits_ns = 3'(bits_ps + 1);
          end
        end else begin
          ticks_ns = 4'(ticks_ps + 1);  
        end
      end
    STOP:
      if(tick) begin                      // Wait until we hit the tick for the stop-bit
        if(ticks_ps == SB_TICK -1) begin
          state_ns = IDLE;                  // Back to IDLE
          ready = 1'b1;
        end else begin
          ticks_ns = 4'(ticks_ps + 1);
        end
      end
  endcase
end

// Output
assign o_data = data_ps;
assign o_ready = ready;

endmodule

