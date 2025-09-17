//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none

module test_tone(                       // Trivial DDS test tone generator
    input var logic i_clk,              // System clock (48MHz)
    input var logic[15:0] i_fcw,        // Frequency control word
    input var logic i_sample_req,       // Sample request signal (Audio rate)
    output logic [31:0] o_sample        // Output sample
);

logic [15:0] phase_acc;                 // Phase accumulator
logic [15:0] fcw;                       // Frequency control word
logic [31:0] sample_out;                // Sample

always_ff @(posedge i_clk) begin
    if (i_sample_req) begin
        phase_acc <= phase_acc + i_fcw; // Increment phase
        sample_out <= 
            {phase_acc, phase_acc};     // Same sawtooth on both L/R channels            
    end
end

assign o_sample = sample_out;           // Registered output

endmodule