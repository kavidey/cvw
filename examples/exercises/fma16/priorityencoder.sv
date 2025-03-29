///////////////////////////////////////////
// priorityencoder.sv
//
// Written: rose@rosethompson.net November 14, 2022
// Modified: kdey@hmc.edu March 28, 2022
//
// Purpose: priority circuit to binary encoding. Modified from cvw/src/generic/binencoder.sv
//
///////////////////////////////////////////
module priorityencoder #(parameter N = 8) (
  input  logic [N-1:0]         A,   // input
  output logic [$clog2(N)-1:0] Y    // binary-encoded output
);

  integer                      index;

  always_comb  begin
    Y = '0;
    for(index = 0; index < N; index++)
      if(A[index] == 1'b1) Y = index[$clog2(N)-1:0];
  end

endmodule