`ifndef __JVS_INT_SIMPLE_TEST_SV__
 `define __JVS_INT_SIMPLE_TEST_SV__
 `include "jvs_irq_base_test.sv"
class jvs_int_simple_test extends jvs_irq_base_test;
   `uvm_component_utils(jvs_int_simple_test)

   function new(string name = "jvs_int_simple_test", uvm_component parent);
      super.new(name, parent);
   endfunction // new

   virtual task do_main_task();
      int_test_finish_int_handler int01_finish_handler, int10_finish_handler;
      int_test_shared_int_handler int00_shared_handler, int11_shared_handler;
      int repeat_times = $urandom_range(3,10);
      `uvm_info(this.get_name(), $psprintf("should trigger %0d ints each vector!", repeat_times), UVM_LOW);
      //int0: 00 and 01 should be triggerd
      int00_shared_handler = int_test_shared_int_handler::type_id::create("int00_shared_handler");
      env.register_irq(`JVS_INT_IRQ_V(0), int00_shared_handler);
      int01_finish_handler = int_test_finish_int_handler::type_id::create("int01_finish_handler");
      env.register_irq(`JVS_INT_IRQ_V(0), int01_finish_handler);

      //int1: 10 should be trigger but 11 should be not
      int10_finish_handler = int_test_finish_int_handler::type_id::create("int10_finish_handler");
      env.register_irq(`JVS_INT_IRQ_V(1), int10_finish_handler);
      int11_shared_handler = int_test_shared_int_handler::type_id::create("int11_shared_handler");
      env.register_irq(`JVS_INT_IRQ_V(1), int11_shared_handler);

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




      fork
	 begin
	    repeat(repeat_times) begin
	       jvs_irq_result_trans tr;
	       int00_shared_handler.get_irq_result(tr);
	       tr.print();
	    end
	 end
	 begin
	    repeat(repeat_times) begin
	       jvs_irq_result_trans tr;
	       int01_finish_handler.get_irq_result(tr);
	       tr.print();
	    end
	 end
	 begin
	    repeat(repeat_times) begin
	       jvs_irq_result_trans tr;
	       int10_finish_handler.get_irq_result(tr);
	       tr.print();
	    end
	 end
      join

      fork
	 begin
	    jvs_irq_result_trans tr;
	    int00_shared_handler.get_irq_result(tr);
	    if (tr != null) begin
	       `uvm_error(this.get_name(), "get result more than expected!");
	    end
	 end
	 begin
	    jvs_irq_result_trans tr;
	    int01_finish_handler.get_irq_result(tr);
	    if (tr != null) begin
	       `uvm_error(this.get_name(), "get result more than expected!");
	    end
	 end
	 begin
	    jvs_irq_result_trans tr;
	    int10_finish_handler.get_irq_result(tr);
	    if (tr != null) begin
	       `uvm_error(this.get_name(), "get result more than expected!");
	    end
	 end
	 begin
	    jvs_irq_result_trans tr;
	    int11_shared_handler.get_irq_result(tr);
	    if (tr != null) begin
	       `uvm_error(this.get_name(), "get result more than expected!");
	    end
	 end
      join
   endtask
endclass
`endif