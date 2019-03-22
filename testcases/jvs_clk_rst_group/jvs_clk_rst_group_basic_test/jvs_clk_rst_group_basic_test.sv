`ifndef __JVS_CLK_RST_GROUP_BASIC_TEST_SV__
 `define __JVS_CLK_RST_GROUP_BASIC_TEST_SV_
class jvs_clk_basic_group_cfg extends jvs_clk_group_cfg;
   `uvm_object_utils(jvs_clk_basic_group_cfg)

   function new(string name = "jvs_clk_basic_group_cfg");
      jvs_gen_clk_cfg clk2div_cfg, clk6div_cfg;
      super.new(name);
      root_clk = jvs_root_clk_cfg::type_id::create("root");
      root_clk.randomize();
      root_clk.period = 10;

      clk2div_cfg = jvs_gen_clk_cfg::type_id::create("clk2div");
      clk2div_cfg.div_ratio = 2;
      clk2div_cfg.sync_rst = 1;
      this.add_gen_clk(clk2div_cfg);

      clk6div_cfg = jvs_gen_clk_cfg::type_id::create("clk6div");
      clk6div_cfg.div_ratio = 6;
      this.add_gen_clk(clk6div_cfg);
   endfunction
endclass

class jvs_clk_basic_group1_cfg extends jvs_clk_group_cfg;
   `uvm_object_utils(jvs_clk_basic_group1_cfg)

   function new(string name = "jvs_clk_basic_group1_cfg");
      jvs_gen_clk_cfg clk2div_cfg, clk3div_cfg;
      super.new(name);
      root_clk = jvs_root_clk_cfg::type_id::create("root");
      root_clk.randomize();
      root_clk.period = 2.5;

      clk2div_cfg = jvs_gen_clk_cfg::type_id::create("clk2div");
      clk2div_cfg.div_ratio = 2;
      this.add_gen_clk(clk2div_cfg);

      clk3div_cfg = jvs_gen_clk_cfg::type_id::create("clk3div");
      clk3div_cfg.div_ratio = 3;
      this.add_gen_clk(clk3div_cfg);
   endfunction
endclass // jvs_clk_basic_group1_cfg

class jvs_clk_basic_top_cfg extends jvs_clk_top_cfg;
   `uvm_object_utils(jvs_clk_basic_top_cfg)

   function new(string name = "jvs_clk_basic_top_cfg");
      jvs_clk_basic_group_cfg group_cfg = jvs_clk_basic_group_cfg::type_id::create("group");
      jvs_clk_basic_group1_cfg group1_cfg = jvs_clk_basic_group1_cfg::type_id::create("group1");
      super.new(name);
      add_group(group_cfg);
      add_group(group1_cfg);
   endfunction
endclass // jvs_clk_basic_top_cfg

class jvs_clk_rst_group_basic_test extends uvm_test;
   jvs_clk_env env;
   jvs_clk_basic_top_cfg cfg;
   `uvm_component_utils(jvs_clk_rst_group_basic_test)

   function new(string name = "jvs_clk_rst_group_basic_test", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = jvs_clk_env::type_id::create("env", this);
      cfg = jvs_clk_basic_top_cfg::type_id::create("cfg");
      cfg.print();

      uvm_config_db#(jvs_clk_top_cfg)::set(this, "*", "cfg", cfg);
   endfunction // build_phase

   virtual task reset_phase(uvm_phase phase);
      phase.raise_objection(this);
      super.reset_phase(phase);
      env.hw_reset();
      phase.drop_objection(this);
   endtask
   
   virtual task main_phase(uvm_phase phase);
      phase.raise_objection(this);
      #10000ns;
      env.hw_reset("group.*");
      #10000ns;      
      env.hw_reset("*.clk2div");
      #10000ns;      
      phase.drop_objection(this);
   endtask
endclass
`endif