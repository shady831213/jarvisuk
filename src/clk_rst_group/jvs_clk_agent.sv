`ifndef __JVS_CLK_AGENT_SV__
 `define __JVS_CLK_AGENT_SV__
virtual class jvs_clk_agent_base#(type CFG_CLASS = jvs_clk_cfg_base) extends uvm_agent;
   jvs_clk_driver_base#(CFG_CLASS) driver;
   `uvm_field_utils_begin(jvs_clk_agent_base#(CFG_CLASS))
   `uvm_field_utils_end

   function new(string name = "jvs_clk_agent_base", uvm_component parent);
      super.new(name, parent);
   endfunction
endclass // jvs_clk_agent_base

class jvs_root_clk_agent extends jvs_clk_agent_base#(jvs_root_clk_cfg);
   `uvm_component_utils_begin(jvs_root_clk_agent)
   `uvm_component_utils_end

   function new(string name = "jvs_root_clk_agent", uvm_component parent);
      super.new(name, parent);
   endfunction
  
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      driver = jvs_root_clk_driver::type_id::create("jvs_root_clk_driver", this);
   endfunction // build_phase   
endclass

class jvs_gen_clk_agent extends jvs_clk_agent_base#(jvs_gen_clk_cfg);
   jvs_clk_vir_seqr seqr;
   `uvm_component_utils_begin(jvs_gen_clk_agent)
   `uvm_component_utils_end

   function new(string name = "jvs_gen_clk_agent", uvm_component parent);
      super.new(name, parent);
   endfunction
  
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      seqr = jvs_clk_vir_seqr::type_id::create("jvs_clk_vir_seqr", this);
      driver = jvs_gen_clk_driver::type_id::create("jvs_gen_clk_driver", this);
   endfunction // build_phase   

   virtual function void connect_phase(uvm_phase phase);
      jvs_gen_clk_driver _driver;
      super.connect_phase(phase);
      $cast(_driver, driver);
      seqr.rst_ana_export.connect(_driver.rst_ana_imp);
   endfunction
endclass // jvs_gen_clk_agent


class jvs_clk_group_agent extends uvm_agent;
   jvs_root_clk_agent root_clk;
   jvs_clk_group_vir_seqr seqr;
   jvs_gen_clk_agent gen_clks[string];
   jvs_clk_group_cfg cfg;
   virtual jvs_clk_group_if vif;
   `uvm_component_utils_begin(jvs_clk_group_agent)
   `uvm_component_utils_end

   function new(string name = "jvs_clk_group_agent", uvm_component parent);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual jvs_clk_group_if)::get(this, "", "jvs_clk_group_if", vif)) begin
	 `uvm_fatal(get_full_name(), "Can't get clk rst group interface!");
      end
      uvm_config_db#(virtual jvs_root_clk_if)::set(this, "jvs_root_clk.*", "jvs_root_clk_if", vif.root_clk_if);

      if(!uvm_config_db#(jvs_clk_group_cfg)::get(this, "", "cfg", cfg)) begin
	 `uvm_fatal(get_full_name(), "Can't get cfg!");
      end
      uvm_config_db#(jvs_root_clk_cfg)::set(this, "jvs_root_clk.*", "cfg", cfg.root_clk);
      root_clk = jvs_root_clk_agent::type_id::create("jvs_root_clk", this);
   
      seqr = jvs_clk_group_vir_seqr::type_id::create("jvs_clk_group_vir_seqr", this);

      foreach(cfg.gen_clks[i]) begin
	 string key = cfg.gen_clks[i].get_name();
	 uvm_config_db#(virtual jvs_gen_clk_if)::set(this, {key, ".*"}, "jvs_gen_clk_if", vif.gen_clk_vifs[i]);
	 uvm_config_db#(jvs_gen_clk_cfg)::set(this, {key, ".*"}, "cfg", cfg.gen_clks[i]);
	 gen_clks[key] = jvs_gen_clk_agent::type_id::create(key, this);
      end
   
   endfunction // build_phase   

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      foreach(gen_clks[i]) begin
	 seqr.clk_seqrs[i] = gen_clks[i].seqr;
	 seqr.rst_ana_export.connect(gen_clks[i].seqr.rst_ana_export);
      end
   endfunction
   
endclass

`endif