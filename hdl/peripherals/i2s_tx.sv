//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none

module i2s_tx (                                   // I2S TX Master (Philips standard)
  input var logic i_aud_clk,                      // Audio clock (6MHz)
  input var logic i_aud_reset_n,                  // Sync reset
  input var logic[15:0] i_left,                   // Left sample in
  input var logic[15:0] i_right,                  // Right sample in
  output logic o_req,                             // Sample request signal
  output logic o_bclk,                            // Bitclock out
  output logic o_ws,                              // Word Select out
  output logic o_sda                              // Serial data out
);

logic bclk_r, ws_r, sda_r, req_r;                 // Registered outputs
logic [15:0] left_r;                              // Sample storage
logic [15:0] right_r;                             // Sample storage

logic bclk_r2;                                    // Edge detection for bclk in system clock domain
always_ff @(posedge i_aud_clk) begin
  bclk_r2 <= bclk_r;                              // Double-flop bclk edge
  req_r <= (bclk_r2 && !bclk_r)                   // Request new samples when 15 bits serialised
    && ws_r && (bit_cnt == 15);
end

logic [1:0] bclk_cnt;                             // Divide bclk from audio clock (6/4=1.5MHz)
always_ff @(posedge i_aud_clk) begin              // using a free running 2-bit counter.
  bclk_cnt <= 2'(bclk_cnt + 1);
end
assign bclk_r = bclk_cnt[1];

logic [4:0] bit_cnt = 4'b1;                       // Serial bit counter 1-16
always_ff @(negedge bclk_r or 
  negedge i_aud_reset_n) begin

  if(!i_aud_reset_n) begin
    bit_cnt <= 1;
  end else begin
    if(bit_cnt >= 16)                             // Count to 16 and then reset to 1
      bit_cnt <= 1;
    else
      bit_cnt <= 4'(bit_cnt + 1);
  end
end

always_ff @(negedge bclk_r or                     // Generate word select signal
  negedge i_aud_reset_n) begin                    

  if(!i_aud_reset_n) begin
    ws_r <= 1'b0;
  end else begin
    if(bit_cnt == 15)
      ws_r <= ~ws_r;                              // Toggle word select signal
  end
end

always_ff @(negedge bclk_r) begin                 // Latch in new samples on last bit of
  if(ws_r && bit_cnt == 15) begin                 // current sample output.
    left_r <= i_left;
    right_r <= i_right;
  end
end

always_ff @(negedge bclk_r) begin                 // Output left or right channel
  sda_r <= ws_r ? right_r[15-bit_cnt]             // serial output
    : left_r[15-bit_cnt];
end

assign o_bclk = bclk_r;                           // Registered outputs
assign o_ws = ws_r;
assign o_sda = sda_r;
assign o_req = req_r;

endmodule
