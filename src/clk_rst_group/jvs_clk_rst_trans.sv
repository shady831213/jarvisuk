`ifndef __JVS_CLK_RST_TRANS_SV__
 `define __JVS_CLK_RST_TRANS_SV__
interface class jvs_clk_period_freq_if;
   pure virtual function realtime get_period();
   pure virtual function realtime get_max_period();
   pure virtual function realtime get_min_period();
   pure virtual function real get_freq();
   pure virtual function real get_max_freq();
   pure virtual function real get_min_freq();
   pure virtual function realtime get_init_delay();
endclass // jvs_clk_period_freq_if

virtual class jvs_clk_cfg_base extends uvm_object;
   int 	rst_cycle = 5;
   `uvm_field_utils_begin(jvs_clk_cfg_base)
     `uvm_field_int(rst_cycle, UVM_ALL_ON)
   `uvm_field_utils_end

   function new(string name = "jvs_clk_cfg_base");
      super.new(name);
   endfunction
endclass // jvs_clk_cfg_base

class jvs_root_clk_cfg extends jvs_clk_cfg_base implements jvs_clk_period_freq_if;
   //should be 1ns, 1ps, 1us, 1ms
   realtime timescale;
   real     period;
   rand bit[7:0] jitter;
   rand bit[7:0] init_delay;

   constraint c_jitter {
      jitter inside {[0:63]};
   }

   constraint c_init_delay {
      init_delay inside {[1:255]};
   }

   `uvm_object_utils_begin(jvs_root_clk_cfg)
     `uvm_field_real(timescale, UVM_ALL_ON)
     `uvm_field_int(jitter, UVM_ALL_ON)
     `uvm_field_real(period, UVM_ALL_ON)
     `uvm_field_int(init_delay, UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name = "jvs_root_clk_cfg");
      super.new(name);
      timescale = 1ns;
      period = 1.0;
   endfunction

   virtual function realtime get_period();
      return this.period * this.timescale;
   endfunction 
   
   virtual function realtime get_max_period();
      return this.get_period() * (1.0 + real'(this.jitter)/255);
   endfunction 

   virtual function realtime get_min_period();
      return this.get_period() * (1.0 - real'(this.jitter)/255);
   endfunction 

   virtual function real get_freq();
      return 1.0 / this.period;
   endfunction 

   virtual function real get_max_freq();
      return this.get_freq() / (1.0 - real'(this.jitter)/255);
   endfunction 

   virtual function real get_min_freq();
      return this.get_freq() / (1.0 + real'(this.jitter)/255);
   endfunction 

   virtual function realtime get_init_delay();
      return (real'(init_delay/255)) * this.get_period();
   endfunction
endclass // jvs_root_clk_cfg

typedef class jvs_clk_group_cfg;
   
class jvs_gen_clk_cfg extends jvs_clk_cfg_base implements jvs_clk_period_freq_if;
   jvs_root_clk_cfg root_clk;
   jvs_clk_group_cfg parent;
   int 	   div_ratio;
   bit     sync_rst;
   
   `uvm_object_utils_begin(jvs_gen_clk_cfg)
     `uvm_field_object(root_clk, UVM_ALL_ON)
     `uvm_field_object(parent, UVM_ALL_ON)
     `uvm_field_int(div_ratio, UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name = "jvs_gen_clk_cfg");
      super.new(name);
      div_ratio = 2;
   endfunction

   function void check_div_ratio();
      if (div_ratio < 2) begin
	 `uvm_fatal(this.get_name(), "div ratio must be at least 2!");
      end
   endfunction

   virtual function realtime get_period();
      check_div_ratio();
      return root_clk.get_period() * div_ratio;
   endfunction 
   
   virtual function realtime get_max_period();
      check_div_ratio();
      return root_clk.get_max_period() * div_ratio;
   endfunction 

   virtual function realtime get_min_period();
      check_div_ratio();
      return root_clk.get_min_period() * div_ratio;
   endfunction 

   virtual function real get_freq();
      check_div_ratio();
      return root_clk.get_freq() / div_ratio;
   endfunction 

   virtual function real get_max_freq();
      check_div_ratio();
      return root_clk.get_max_freq() / div_ratio;
   endfunction 

   virtual function real get_min_freq();
      check_div_ratio();
      return root_clk.get_min_freq() / div_ratio;
   endfunction 

   virtual function realtime get_init_delay();
      check_div_ratio();
      return root_clk.get_init_delay();
   endfunction
   
endclass // jvs_gen_clk_cfg

class jvs_clk_group_cfg extends jvs_clk_cfg_base;
   jvs_root_clk_cfg root_clk;
   jvs_gen_clk_cfg gen_clks[$];

   `uvm_object_utils_begin(jvs_clk_group_cfg)
     `uvm_field_object(root_clk, UVM_ALL_ON)
     `uvm_field_queue_object(gen_clks, UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name = "jvs_clk_group_cfg");
      super.new(name);
   endfunction

   function void add_gen_clk(jvs_gen_clk_cfg clk);
      clk.root_clk = this.root_clk;
      clk.parent = this;
      gen_clks.push_back(clk);
   endfunction
endclass // jvs_clk_group_cfg

class jvs_clk_top_cfg extends jvs_clk_cfg_base;
   jvs_clk_group_cfg groups[string];
   `uvm_object_utils_begin(jvs_clk_top_cfg)
     `uvm_field_aa_object_string(groups, UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name = "jvs_clk_top_cfg");
      super.new(name);
   endfunction

   function void add_group(jvs_clk_group_cfg group);
      this.groups[group.get_name()] = group;
   endfunction
   
endclass // jvs_clk_top_cfg

virtual class jvs_clk_trans_base#(type CFG_CLASS = jvs_clk_period_freq_if) extends uvm_sequence_item;
   CFG_CLASS cfg;
   int 	cycle_cnt;
   bit 	is_root;
   realtime start_time;
   realtime cur_time;

   `uvm_field_utils_begin(jvs_clk_trans_base)
     `uvm_field_real(start_time, UVM_ALL_ON)
     `uvm_field_real(cur_time, UVM_ALL_ON)
     `uvm_field_int(cycle_cnt, UVM_ALL_ON)
     `uvm_field_int(is_root, UVM_ALL_ON)
   `uvm_field_utils_end

   function new(string name = "jvs_clk_trans_base");
      super.new(name);
   endfunction

   virtual  function void start_clk();
      start_time = $realtime;
      cycle_cnt = 0;
   endfunction

   virtual  function void sample_clk(input int cycle_cnt);
      cur_time = $realtime;
      this.cycle_cnt += cycle_cnt;
   endfunction

   virtual  function realtime get_sampled_mean_period();
      return (cur_time - start_time)/cycle_cnt;
   endfunction 

   virtual  function realtime get_sampled_mean_freq();
      return 1.0 / this.get_sampled_mean_period();
   endfunction 
   
endclass // jvs_clk_trans_base

class jvs_root_clk_trans extends jvs_clk_trans_base#(jvs_root_clk_cfg);
   rand bit[7:0] jitter;
   rand bit jitter_flag;
   
   constraint c_period {
      jitter inside{[0:cfg.jitter]};
   }

   `uvm_object_utils_begin(jvs_root_clk_trans)
     `uvm_field_object(cfg, UVM_ALL_ON)
     `uvm_field_int(jitter, UVM_ALL_ON)
     `uvm_field_int(jitter_flag, UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name = "jvs_root_clk_trans");
      super.new(name);
      is_root = 1;
   endfunction
   
   virtual function realtime get_half_period();
      if (jitter_flag) begin
	 return (cfg.get_period()/2.0) * (1.0 - real'(this.jitter)/255);
      end
      return (cfg.get_period()/2.0) * (1.0 + real'(this.jitter)/255);
   endfunction
endclass // jvs_root_clk_trans

class jvs_gen_clk_trans extends jvs_clk_trans_base#(jvs_gen_clk_cfg);
   `uvm_object_utils_begin(jvs_gen_clk_trans)
     `uvm_field_object(cfg, UVM_ALL_ON)
   `uvm_object_utils_end
   function new(string name = "jvs_gen_clk_trans");
      super.new(name);
      is_root = 0;
   endfunction
endclass // jvs_gen_clk_trans

class jvs_clk_rst_trans extends uvm_sequence_item;
   uvm_event_pool rst_event_pool;
   uvm_event_pool begin_event_pool;
   uvm_event_pool end_event_pool;
   string pattern;
   
   `uvm_object_utils_begin(jvs_clk_rst_trans)
     `uvm_field_object(rst_event_pool, UVM_ALL_ON)
     `uvm_field_object(begin_event_pool, UVM_ALL_ON)
     `uvm_field_object(end_event_pool, UVM_ALL_ON)
     `uvm_field_string(pattern, UVM_ALL_ON)
   `uvm_object_utils_end
   
   function new(string name = "jvs_clk_rst_trans");
      super.new(name);
      rst_event_pool = new();
      begin_event_pool = new();
      end_event_pool = new();
   endfunction

   task wait_rst();
      wait_event_pool(this.rst_event_pool);
   endtask

   task wait_begin();
      wait_event_pool(this.begin_event_pool);
   endtask

   task wait_end();
      wait_event_pool(this.end_event_pool);
   endtask

/* -----\/----- EXCLUDED -----\/-----
   function void reset_event_status();
      reset_event_pool_status(this.rst_event_pool);
      reset_event_pool_status(this.begin_event_pool);
      reset_event_pool_status(this.end_event_pool);
   endfunction // reset_event_status

   protected function reset_event_pool_status(uvm_event_pool event_pool);
      string key;
      while(event_pool.next(key)) begin
	 uvm_event e = event_pool.get(key);
	 e.reset();
	 event_pool.delete(key);
      end
   endfunction
 -----/\----- EXCLUDED -----/\----- */

   protected task wait_event_pool(uvm_event_pool event_pool);
      string key;
      //wait to start
      while(!event_pool.num()) begin
	 #1ns;
      end
      while(event_pool.next(key)) begin
	 uvm_event e = event_pool.get(key);
	 e.wait_on();
      end
   endtask

endclass
`endif