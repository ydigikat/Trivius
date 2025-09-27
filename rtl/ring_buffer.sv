//-----------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
`default_nettype none

module ring_buffer #(
    parameter unsigned BUF_SIZE=16,
    parameter unsigned DATA_WIDTH=8,
    parameter unsigned BUF_ADDR_SIZE=$clog2(BUF_SIZE)
) (
    input var logic                   i_clk,
    input var logic                   i_rst_n,

    input var logic                   i_write_en,
    input var logic[DATA_WIDTH-1:0]   i_write_data,

    input var logic                   i_read_en,
    output logic[DATA_WIDTH-1:0]      o_read_data,

    output logic                      o_empty,
    output logic                      o_full
);

  typedef logic [BUF_ADDR_SIZE-1:0] buf_ptr_t;

  logic [DATA_WIDTH-1:0] buffer[BUF_SIZE];
  buf_ptr_t head, head_n;
  buf_ptr_t tail, tail_n;

  //-----------------------------------------------------------------------------
  // State registers
  //-----------------------------------------------------------------------------
  always_ff @(posedge i_clk) begin
    if (!i_rst_n) begin
      head <= 0;
      tail <= 0;
    end else begin
      head <= head_n;
      tail <= tail_n;
    end
  end

  //-----------------------------------------------------------------------------
  // Buffer write
  //-----------------------------------------------------------------------------
  always_ff @(posedge i_clk) begin
    if (i_write_en && !o_full) begin
      buffer[head] <= i_write_data;
    end
  end

  //-----------------------------------------------------------------------------
  // Next state logic
  //-----------------------------------------------------------------------------
  always_comb begin
    head_n = head;
    tail_n = tail;

    if (i_write_en && !o_full) begin
      head_n = buf_ptr_t'((head + 1) % BUF_SIZE);
    end

    if (i_read_en && !o_empty) begin
      tail_n = buf_ptr_t'((tail + 1) % BUF_SIZE);
    end
  end

  //-----------------------------------------------------------------------------
  // Output logic
  //-----------------------------------------------------------------------------
  assign o_read_data = buffer[tail];
  assign o_empty = (head == tail);
  assign o_full = buf_ptr_t'((head + 1) % BUF_SIZE) == tail;

endmodule

`default_nettype wire
