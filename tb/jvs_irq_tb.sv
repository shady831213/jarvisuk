`ifndef __JVS_IRQ_TB_SV__
 `define __JVS_IRQ_TB_SV__
`include "uvm_macros.svh"
import uvm_pkg::*;
import jvs_pkg::*;

module jvs_irq_tb();
   logic clk;
   logic rst;

   initial begin
      clk = 0;
      #50ns;
      forever begin
	 #50ns;
	 clk = ~clk;
      end
   end

   initial begin
      rst = 0;
      #1000ns;
      rst = 1;
      #100ns;
      rst = 0;
   end

   jvs_int_if int_if();
   assign int_if.clk = clk;

   initial begin
      uvm_config_db#(virtual jvs_int_if)::set(null, "uvm_test_top.*.jvs_int_agent", "jvs_int_if", int_if);
      run_test();
   end

   `JVS_WAVE(jvs_irq_tb)
   
endmodule
`endif