`ifndef __JVS_INT_IF_SV__
 `define __JVS_INT_IF_SV__
interface jvs_int_if ();
   logic clk;
   bit [`JVS_MAX_INT_PIN_NUM-1:0] interrupt;
endinterface
`endif