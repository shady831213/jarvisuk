`ifndef __JVS_CLK_VIR_SEQR_SV__
 `define __JVS_CLK_VIR_SEQR_SV__
class jvs_clk_vir_seqr extends uvm_virtual_sequencer;
   uvm_analysis_export#(jvs_clk_rst_trans) rst_ana_export;
   `uvm_component_utils(jvs_clk_vir_seqr)
   function new(string name = "jvs_clk_vir_seqr", uvm_component parent = null);
      super.new(name, parent);
      rst_ana_export = new("rst_ana_export", this);
   endfunction // new
endclass // jvs_clk_vir_seqr

class jvs_clk_group_vir_seqr extends jvs_clk_vir_seqr;
   jvs_clk_vir_seqr clk_seqrs[string];
   
   `uvm_component_utils_begin(jvs_clk_group_vir_seqr)
     `uvm_field_aa_object_string(clk_seqrs, UVM_ALL_ON)
   `uvm_component_utils_end
   function new(string name = "jvs_clk_group_vir_seqr", uvm_component parent = null);
      super.new(name, parent);
   endfunction // new
endclass // jvs_clk_group_vir_seqr

class jvs_clk_top_vir_seqr extends jvs_clk_vir_seqr;
   jvs_clk_group_vir_seqr group_seqrs[string];
   
   `uvm_component_utils_begin(jvs_clk_top_vir_seqr)
     `uvm_field_aa_object_string(group_seqrs, UVM_ALL_ON)
   `uvm_component_utils_end
   function new(string name = "jvs_clk_top_vir_seqr", uvm_component parent = null);
      super.new(name, parent);
   endfunction // new

   virtual task hw_reset(string pattern = "*");
      jvs_clk_rst_trans tr = new();
      tr.pattern = pattern;
      rst_ana_export.write(tr);
      tr.wait_end();
      `uvm_info(this.get_name(), $psprintf("@%0t hw_reset  %0s done!", $realtime, pattern), UVM_LOW);
   endtask // hw_global_reset

   
endclass
`endif