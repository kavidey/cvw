`include "tests.vh"

/* verilator lint_off STMTDLY */
module testbench_fma16;
  string Tests[];

  logic        clk, reset;
  logic [15:0] x, y, z, rexpected, result;
  logic [7:0]  ctrl;
  logic        mul, add, negp, negz;
  logic [1:0]  roundmode;
  logic [31:0] vectornum, errors;
  logic [75:0] testvectors[100000000:0];
  integer offset;
  logic [3:0]  flags, flagsexpected; // Invalid, Overflow, Underflow, Inexact

  // instantiate device under test
  fma16 dut(x, y, z, mul, add, negp, negz, roundmode, result, flags);

  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors and pulse reset
  initial
    begin
      if (TEST_MUL)
        Tests = {Tests, mul_tests};
      if (TEST_ADD)
        Tests = {Tests, add_tests};
      if (TEST_FMA)
        Tests = {Tests, fma_tests};
      if (TEST_SPECIAL)
        Tests = {Tests, special_tests};
      if (TEST_EXTRA)
        Tests = {Tests, extra_tests};

      for (int i = 0; i < $size(Tests); i++) begin
          offset = 0;
          for (int j = 0; j < $size(testvectors); j++) begin
            if (testvectors[offset] === 'x)
              break;
            else
              offset = offset + 1;
          end
          $readmemh($sformatf("work/%s", Tests[i]), testvectors, offset);
      end
      vectornum = 0; errors = 0;
      reset = 1; #22; reset = 0;

      if (offset < 100) begin
        $dumpfile("fma16.vcd");
        $dumpvars(0, testbench_fma16);
      end
    end

  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; {x, y, z, ctrl, rexpected, flagsexpected} = testvectors[vectornum];
      {roundmode, mul, add, negp, negz} = ctrl[5:0];
    end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip during reset
      if (result !== rexpected | flags !== flagsexpected) begin  // check result
        $display("Error: inputs %h * %h + %h", x, y, z);
        $display("  result = %h (%h expected) flags = %b (%b expected)", 
          result, rexpected, flags, flagsexpected);
        errors = errors + 1;
      end
      vectornum = vectornum + 1;
      if (testvectors[vectornum] === 'x) begin 
        $display("%d tests completed with %d errors", 
	           vectornum, errors);
        $stop;
      end
    end
endmodule
