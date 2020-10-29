`ifndef __JVS_CLK_IFS_SV__
 `define __JVS_CLK_IFS_SV__
interface jvs_root_clk_if();
   logic clock;
endinterface // jvs_root_clk_if

interface jvs_gen_clk_if();
   logic root_clock;
   logic clock;
   logic reset_n;
   logic rst_process;

   clocking clk_driver @(root_clock);
      inout clock;
   endclocking // clk_driver

   clocking ctrl_driver @(posedge clock);
      output rst_process;
      output reset_n;
   endclocking
endinterface // jvs_gen_clk_if

module jvs_clk_group_if#(parameter string name="", parameter string path="*")();
   import uvm_pkg::*;
   jvs_root_clk_if root_clk_if();
   jvs_gen_clk_if gen_clk_ifs[`JVS_MAX_CLK_GROUP_CLK_NUM-1:0]();

   genvar    i;
   generate
      for (i = 0; i < `JVS_MAX_CLK_GROUP_CLK_NUM; i++) begin: gen_clk_loop
         assign gen_clk_ifs[i].root_clock = root_clk_if.clock;
         initial begin
            uvm_config_db#(virtual jvs_gen_clk_if)::set(uvm_root::get(), $sformatf("%s.%s",path, name), $sformatf("jvs_gen_clk_if[%0d]", i), gen_clk_ifs[i]);
         end
      end
   endgenerate
   initial begin
      uvm_config_db#(virtual jvs_root_clk_if)::set(uvm_root::get(), $sformatf("%s.%s",path, name), "jvs_root_clk_if", root_clk_if);
   end

endmodule
`endif