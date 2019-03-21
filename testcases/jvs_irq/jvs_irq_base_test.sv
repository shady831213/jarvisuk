`ifndef __JVS_IRQ_BASE_TEST_SV__
 `define __JVS_IRQ_BASE_TEST_SV__
class irq_drv_seq extends uvm_sequence_base;
   local static irq_drv_seq inst;
   jvs_int_sequencer int_seqr;
   `uvm_object_utils_begin(irq_drv_seq)
   `uvm_object_utils_end

   function new(string name = "irq_drv_seq");
      super.new(name);
   endfunction // new

   static function irq_drv_seq get_irq_drv_seq();
      if (inst == null) begin
	 inst = irq_drv_seq::type_id::create("irq_drv_seq");
      end
      return inst;
   endfunction // get_irq_drv_seq

   task trigger_int(bit[`JVS_MAX_INT_PIN_NUM-1:0] vector);
      jvs_int_drv_trans trans;
      `uvm_create_on(trans, int_seqr)
      trans.irq_vector = vector;
      trans.set = 1;
      `uvm_send(trans);
   endtask // trigger_int

   task clear_int(bit[`JVS_MAX_INT_PIN_NUM-1:0] vector);
      jvs_int_drv_trans trans;
      `uvm_create_on(trans, int_seqr)
      trans.irq_vector = vector;
      trans.set = 0;
      `uvm_send(trans);      
   endtask
endclass // irq_drv_seq

class int_test_finish_int_handler extends jvs_irq_handler;
   int irq_cnt;
   `uvm_object_utils_begin(int_test_finish_int_handler)
   `uvm_object_utils_end
   function new(string name = "int_test_finish_int_handler");
      super.new(name);
   endfunction // new

   virtual task do_handle(jvs_irq_trans irq_tr);
      `uvm_info(this.get_name(), $psprintf("get %0d irq!", irq_cnt), UVM_LOW);
      irq_tr.print();
      if (irq_tr.get_root_irq_source().get_irq_type() == jvs_irq_trans::INT_IRQ) begin
	 `uvm_info(this.get_name(), $psprintf("clear %0d irq!", irq_cnt), UVM_LOW);
	 irq_drv_seq::get_irq_drv_seq().clear_int(irq_tr.get_root_irq_source().irq_vector);
      end
      irq_cnt++;
      irq_tr.handle_state = jvs_irq_trans::FINISH;
      `uvm_info(this.get_name(), "finish irq_trans", UVM_LOW);
   endtask // do_handle

   virtual function jvs_irq_result_trans gen_result(jvs_irq_trans irq_tr);
      jvs_irq_result_trans result = jvs_irq_result_trans::type_id::create($psprintf("%0s_result_%0d", this.get_name(), irq_cnt));
      result.irq_vector = irq_tr.irq_vector;
      return result;
   endfunction
endclass

class int_test_shared_int_handler extends jvs_irq_handler;
   int irq_cnt;
   `uvm_object_utils_begin(int_test_shared_int_handler)
   `uvm_object_utils_end
   function new(string name = "int_test_shared_int_handler");
      super.new(name);
   endfunction // new

   virtual task do_handle(jvs_irq_trans irq_tr);
      `uvm_info(this.get_name(), $psprintf("get %0d irq!", irq_cnt), UVM_LOW);
      irq_tr.print();
      irq_cnt++;
      irq_tr.handle_state = jvs_irq_trans::THROUGH;
      `uvm_info(this.get_name(), "through irq_trans", UVM_LOW);
   endtask // do_handle

   virtual function jvs_irq_result_trans gen_result(jvs_irq_trans irq_tr);
      jvs_irq_result_trans result = jvs_irq_result_trans::type_id::create($psprintf("%0s_result_%0d", this.get_name(), irq_cnt));
      result.irq_vector = irq_tr.irq_vector;
      return result;
   endfunction
endclass // int_test_shared_int_handler

class int_test_redirect_int_handler extends jvs_irq_handler;
   int irq_cnt;
   jvs_irq_env env;
   bit [`JVS_MAX_IRQ_VECTOR_WIDTH-1:0] redirect_vector;
   jvs_irq_trans::irq_handle_state_e action;
   
   `uvm_object_utils_begin(int_test_redirect_int_handler)
   `uvm_object_utils_end
   function new(string name = "int_test_redirect_int_handler");
      super.new(name);
   endfunction // new

   virtual task do_handle(jvs_irq_trans irq_tr);
      `uvm_info(this.get_name(), $psprintf("get %0d irq!", irq_cnt), UVM_LOW);
      irq_tr.print();
      irq_cnt++;
      irq_tr.handle_state = action;
      env.trigger_soft_irq(irq_tr.redirect(redirect_vector));
      `uvm_info(this.get_name(), "redirect irq_trans", UVM_LOW);
   endtask // do_handle

   virtual function jvs_irq_result_trans gen_result(jvs_irq_trans irq_tr);
      return null;
   endfunction
endclass

virtual class jvs_irq_base_test extends uvm_test;
   jvs_irq_env env;
   `uvm_field_utils_begin(jvs_irq_base_test)
   `uvm_field_utils_end

   function new(string name = "jvs_irq_base_test", uvm_component parent);
      super.new(name, parent);
   endfunction // new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      uvm_config_db#(int)::set(this, "*.jvs_int_agent", "is_active", UVM_ACTIVE);
      env= jvs_irq_env::type_id::create("jvs_irq_env", this);
   endfunction // build_phase

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      irq_drv_seq::get_irq_drv_seq().int_seqr = env.jvs_int_ag.int_seqr;
   endfunction // connect_phase

   virtual task main_phase(uvm_phase phase);
      phase.raise_objection(phase);
      super.main_phase(phase);
      do_main_task();
      phase.drop_objection(phase);
   endtask // main_phase

   pure virtual task do_main_task();
      
endclass
`endif