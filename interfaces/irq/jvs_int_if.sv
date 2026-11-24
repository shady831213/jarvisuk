`ifndef __JVS_INT_IF_SV__
 `define __JVS_INT_IF_SV__
interface jvs_int_if #(parameter int PIN_COUNT = `JVS_MAX_INT_PIN_NUM) ();
   logic clk;
   bit [PIN_COUNT-1:0] interrupt;
   if (PIN_COUNT < 1 || PIN_COUNT > `JVS_MAX_INT_PIN_NUM) begin : invalid_width
      $fatal(1, "JVS_IRQ_PIN_COUNT: PIN_COUNT=%0d must be in 1..%0d", PIN_COUNT, `JVS_MAX_INT_PIN_NUM);
   end
endinterface
`endif
