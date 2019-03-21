`ifndef __JVS_SOFT_IRQ_TEST_SV__
 `define __JVS_SOFT_IRQ_TEST_SV__
 `include "jvs_irq_base_test.sv"
class jvs_soft_irq_test extends jvs_irq_base_test;
   `uvm_component_utils(jvs_soft_irq_test)

   function new(string name = "jvs_soft_irq_test", uvm_component parent);
      super.new(name, parent);
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
      env.register_irq(`JVS_INT_IRQ_V(0), int0_redirect_handler);

      //int1: should be triggerd and redirect to soft irq 1
      int1_redirect_handler = int_test_redirect_int_handler::type_id::create("int1_redirect_handler");
      int1_redirect_handler.action = jvs_irq_trans::FINISH;
      int1_redirect_handler.env = env;
      int1_redirect_handler.redirect_vector = `JVS_SOFT_IRQ_V(1);
      env.register_irq(`JVS_INT_IRQ_V(1), int1_redirect_handler);

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
	       irq_drv_seq::get_irq_drv_seq().trigger_int(0);
	       #($urandom_range(1,100) * 1ns);
	       `uvm_info(this.get_name(), "trigger int 1", UVM_LOW);
	       irq_drv_seq::get_irq_drv_seq().trigger_int(1);
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