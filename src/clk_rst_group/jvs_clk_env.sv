`ifndef __JVS_CLK_ENV_SV__
 `define __JVS_CLK_ENV_SV__
class jvs_clk_env extends uvm_env;
   local jvs_clk_top_vir_seqr seqr;
   local jvs_clk_group_agent groups[string];
   local jvs_clk_top_cfg cfg;

   `uvm_component_utils(jvs_clk_env)
   function new(string name = "jvs_clk_env", uvm_component parent = null);
      super.new(name, parent);
      seqr = jvs_clk_top_vir_seqr::type_id::create("jvs_clk_top_vir_seqr", this);
   endfunction // new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(jvs_clk_top_cfg)::get(this, "", "cfg", cfg)) begin
	 `uvm_fatal(get_full_name(), "Can't get cfg!");
      end
      foreach(cfg.groups[i]) begin
	 string key = cfg.groups[i].get_name();
	 uvm_config_db#(jvs_clk_group_cfg)::set(this, key, "cfg", cfg.groups[i]);
	 groups[key] = jvs_clk_group_agent::type_id::create(key, this);
      end
   
   endfunction // build_phase   

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      foreach(groups[i]) begin
	 seqr.group_seqrs[i] = groups[i].seqr;
	 seqr.rst_ana_export.connect(groups[i].seqr.rst_ana_export);
      end
   endfunction
   
   task hw_reset(string pattern="*");
      seqr.hw_reset(pattern);
   endtask
endclass
`endif