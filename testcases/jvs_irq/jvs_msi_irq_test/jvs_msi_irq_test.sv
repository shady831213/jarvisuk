`ifndef __JVS_MSI_IRQ_TEST_SV__
 `define __JVS_MSI_IRQ_TEST_SV__
 `include "jvs_irq_base_test.sv"
class msi_irq_test_msi_monitor extends jvs_msi_monitor;
   semaphore sem_p, sem_c;
   local jvs_irq_trans tr_input;

   `uvm_component_utils(msi_irq_test_msi_monitor)

   function new(string name = "msi_irq_test_msi_monitor", uvm_component parent);
      super.new(name, parent);
      sem_p = new(0);
      sem_c = new(0);
   endfunction // new

   task trigger_msi(bit[`JVS_MAX_INT_PIN_NUM-1:0] vector);
      sem_p.get(1);
      tr_input = jvs_irq_trans::type_id::create("msi_irq");
      tr_input.irq_vector = vector;
      sem_c.put(1);
   endtask

   protected virtual task monitor_msi(output jvs_irq_trans tr);
      sem_p.put(1);
      sem_c.get(1);
      tr = tr_input;
   endtask
endclass

class jvs_msi_irq_test extends jvs_irq_base_test;
   msi_irq_test_msi_monitor msi_monitor;
   
   `uvm_component_utils(jvs_msi_irq_test)

   function new(string name = "jvs_msi_irq_test", uvm_component parent);
      super.new(name, parent);
      msi_monitor = msi_irq_test_msi_monitor::type_id::create("msi_irq_test_msi_monitor", this);
      uvm_config_db#(jvs_msi_monitor)::set(this, "jvs_irq_env", "jvs_msi_monitor", msi_monitor);
   endfunction // new

   virtual task do_main_task();
      int_test_redirect_int_handler int0_redirect_handler, int1_redirect_handler, int0_soft_redirect_handler;
      int_test_finish_int_handler int10_finish_handler;
      int_test_shared_int_handler int11_shared_handler;
      int repeat_times = $urandom_range(3,10);
      `uvm_info(this.get_name(), $psprintf("should trigger %0d ints each vector!", repeat_times), UVM_LOW);
      //int0: should be triggerd and redirect to soft irq 0
      int0_redirect_handler = int_test_redirect_int_handler::type_id::create("int0_redirect_handler");
      int0_redirect_handler.action = jvs_irq_trans::THROUGH;
      int0_redirect_handler.env = env;
      int0_redirect_handler.redirect_vector = `JVS_SOFT_IRQ_V(0);
      env.register_irq(`JVS_MSI_IRQ_V(0), int0_redirect_handler);

      //int1: should be triggerd and redirect to soft irq 1
      int1_redirect_handler = int_test_redirect_int_handler::type_id::create("int1_redirect_handler");
      int1_redirect_handler.action = jvs_irq_trans::FINISH;
      int1_redirect_handler.env = env;
      int1_redirect_handler.redirect_vector = `JVS_SOFT_IRQ_V(1);
      env.register_irq(`JVS_MSI_IRQ_V(1), int1_redirect_handler);

      //soft int0: should be triggerd and redirect to soft irq 1
      int0_soft_redirect_handler = int_test_redirect_int_handler::type_id::create("int0_soft_redirect_handler");
      int0_soft_redirect_handler.action = jvs_irq_trans::THROUGH;
      int0_soft_redirect_handler.env = env;
      int0_soft_redirect_handler.redirect_vector = `JVS_SOFT_IRQ_V(1);
      env.register_irq(`JVS_SOFT_IRQ_V(0), int0_soft_redirect_handler);

      //soft int1: 10 should be trigger but 11 should be not
      int10_finish_handler = int_test_finish_int_handler::type_id::create("int10_finish_handler");
      env.register_irq(`JVS_SOFT_IRQ_V(1), int10_finish_handler);
      int11_shared_handler = int_test_shared_int_handler::type_id::create("int11_shared_handler");
      env.register_irq(`JVS_SOFT_IRQ_V(1), int11_shared_handler);

      fork
	 begin
	    repeat(repeat_times) begin
	       `uvm_info(this.get_name(), "trigger int 0", UVM_LOW);
	       msi_monitor.trigger_msi(0);
	       #($urandom_range(1,100) * 1ns);
	       `uvm_info(this.get_name(), "trigger int 1", UVM_LOW);
	       msi_monitor.trigger_msi(1);
	       #($urandom_range(1,100) * 1ns);
	    end
	 end
      join_none


      //1 int0 redirect: repeat_times = repeat_times
      //1 int1 redirect: repeat_times = repeat_times+repeat_times
      repeat(2*repeat_times) begin
	 jvs_irq_result_trans tr;
	 int10_finish_handler.get_irq_result(tr);
	 tr.print();
      end

      //should be timeout
      begin
	 jvs_irq_result_trans tr;
	 int10_finish_handler.get_irq_result(tr);
	 if (tr != null) begin
	    `uvm_error(this.get_name(), "get result more than expected!");
	 end
      end
   endtask
endclass
`endif