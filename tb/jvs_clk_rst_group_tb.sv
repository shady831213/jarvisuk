`ifndef __JVS_CLK_RST_GROUP_TB_SV__
 `define __JVS_CLK_RST_GROUP_TB_SV__
`include "uvm_macros.svh"
import uvm_pkg::*;
import jvs_pkg::*;


module jvs_clk_rst_group_tb();
   jvs_clk_group_if#(.name("group")) clk_group_if();
   jvs_clk_group_if#(.name("group1")) clk_group1_if();

   initial begin
      #0;
      run_test();
   end
   `JVS_WAVE(jvs_clk_rst_group_tb)   
endmodule

`endif
