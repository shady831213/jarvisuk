`ifndef __JVS_CLK_DRIVER_SV__
 `define __JVS_CLK_DRIVER_SV__
virtual class jvs_clk_driver_base#(type CFG_CLASS= jvs_clk_cfg_base) extends uvm_driver#(jvs_clk_trans_base#(CFG_CLASS));
   CFG_CLASS cfg;
   `uvm_field_utils_begin(jvs_clk_driver_base#(CFG_CLASS))
     `uvm_field_object(cfg,UVM_ALL_ON)
   `uvm_field_utils_end

   function new(string name = "jvs_clk_driver_base", uvm_component parent);
      super.new(name, parent);
   endfunction // new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(CFG_CLASS)::get(this, "", "cfg", cfg)) begin
	 `uvm_fatal(get_full_name(), "Can't get cfg!");
      end
   endfunction
endclass // jvs_clk_driver_base

class jvs_root_clk_driver extends jvs_clk_driver_base#(jvs_root_clk_cfg);
   jvs_root_clk_trans trans;
   virtual jvs_root_clk_if vif;
   `uvm_component_utils_begin(jvs_root_clk_driver)
     `uvm_field_object(trans, UVM_ALL_ON)
   `uvm_component_utils_end

   function new(string name = "jvs_root_clk_driver", uvm_component parent);
      super.new(name, parent);
   endfunction // new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual jvs_root_clk_if)::get(this, "", "jvs_root_clk_if", vif)) begin
	 `uvm_fatal(get_full_name(), "Can't get root clk interface!");
      end
      trans = jvs_root_clk_trans::type_id::create("jvs_root_clk");
      trans.cfg = cfg;
   endfunction // build_phase

   virtual task run_phase(uvm_phase phase);
      realtime delay;
      super.run_phase(phase);
      vif.clock = 0;
      delay = cfg.get_init_delay();
      #(delay);
      forever begin
	 realtime half_period;
	 vif.clock = ~vif.clock;
	 trans.randomize();
	 half_period = trans.get_half_period();
	 #(half_period);
      end
   endtask
endclass // jvs_root_clk_driver

`uvm_analysis_imp_decl(_clk_rst_driver)

class jvs_gen_clk_driver extends jvs_clk_driver_base#(jvs_gen_clk_cfg);
   uvm_analysis_imp_clk_rst_driver#(jvs_clk_rst_trans, jvs_gen_clk_driver) rst_ana_imp;
   uvm_tlm_fifo#(jvs_clk_rst_trans) rst_fifo;
   virtual 	  jvs_gen_clk_if vif;
   `uvm_component_utils_begin(jvs_gen_clk_driver)
   `uvm_component_utils_end

   function new(string name = "jvs_gen_clk_driver", uvm_component parent);
      super.new(name, parent);
      rst_fifo = new("rst_fifo", this);
      rst_ana_imp = new("rst_ana_imp", this);
   endfunction // new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual jvs_gen_clk_if)::get(this, "", "jvs_gen_clk_if", vif)) begin
	 `uvm_fatal(get_full_name(), "Can't get gen clk rst interface!");
      end
   endfunction // build_phase

   local task drive_clk();
      bit [31:0] cycle_cnt;
      int 	 i;
      forever begin
	 @vif.clk_driver;
	 if(cycle_cnt == cfg.div_ratio - 1) begin
	    vif.clk_driver.clock <= ~vif.clk_driver.clock;
	    cycle_cnt = 0;
	 end
	 else begin
	    cycle_cnt++;
	 end
      end
   endtask // drive_clk

   local task reset();
      if (cfg.sync_rst) begin
	 vif.ctrl_driver.reset_n <= 0;
      end
      else begin
	 realtime delay = cfg.root_clk.get_period() * real'($urandom_range(1,255))/255;
	 #(delay);
	 vif.reset_n = 0;
      end
      repeat(cfg.rst_cycle) begin
	 @vif.ctrl_driver;
      end
      vif.ctrl_driver.reset_n <= 1;
      @vif.ctrl_driver;
   endtask // reset

   local task reset_begin();
      vif.rst_process = 1;
      repeat(3) begin
	 @vif.clk_driver;
      end
   endtask // reset_begin

   local task reset_end();
      repeat(2) begin
	 @vif.ctrl_driver;
      end
      vif.ctrl_driver.rst_process <= 0;
      @vif.ctrl_driver;
   endtask // reset_end

   local task reset_process();
      jvs_clk_rst_trans tr;
      uvm_event begin_e;
      uvm_event rst_e;
      uvm_event end_e;
      rst_fifo.peek(tr);
      begin_e = tr.begin_event_pool.get(this.get_name());
      end_e = tr.end_event_pool.get(this.get_name());
      rst_e = tr.rst_event_pool.get(this.get_name());

      reset_begin();
      begin_e.trigger();
      tr.wait_begin();
      reset();
      rst_e.trigger();
      tr.wait_rst();
      reset_end();
      end_e.trigger();

      rst_fifo.get(tr);
   endtask // reset_process

   virtual task run_phase(uvm_phase phase);
      vif.clock = 0;
      vif.reset_n = 1;
      vif.rst_process= 0;
      repeat(cfg.div_ratio-2) begin
	 @vif.clk_driver;
      end
      fork
	 drive_clk();
      join_none
      forever begin
	 reset_process();
      end
   endtask // run_phase

   virtual function void write_clk_rst_driver (jvs_clk_rst_trans tr);
      if (uvm_is_match(tr.pattern, {cfg.parent.get_name(), ".", cfg.get_name()})) begin
	 if (!rst_fifo.try_put(tr)) begin
	    `uvm_fatal(this.get_name(), "hw reset occurs while previous hw reset in processing!");
	 end
      end
      else begin
	 uvm_event end_e =  tr.end_event_pool.get(this.get_name());
	 end_e.trigger();
      end
   endfunction
endclass  
`endif