`ifndef __JVS_IRQ_HANDLER_SV__
 `define __JVS_IRQ_HANDLER_SV__
typedef jvs_common_type_queue#(jvs_irq_result_trans) jvs_irq_result_queue;

virtual class jvs_irq_handler extends uvm_object;
   protected jvs_irq_result_queue irq_result_fifo;
   protected int fifo_size = 1000;
   `uvm_field_utils_begin(jvs_irq_handler)
     `uvm_field_int(fifo_size, UVM_ALL_ON)
   `uvm_field_utils_end

   function new(string name = "jvs_irq_handler");
      super.new(name);
      irq_result_fifo = new();
   endfunction // new

   pure virtual task do_handle(jvs_irq_trans irq_tr);

   pure virtual function jvs_irq_result_trans gen_result(jvs_irq_trans irq_tr);

   task handle(jvs_irq_trans irq_tr);
      do_handle(irq_tr);
      put_result(gen_result(irq_tr));
   endtask // handle

   local task put_result(jvs_irq_result_trans result);
      if (result != null) begin
	 irq_result_fifo.lock.get(1);
	 if (irq_result_fifo.queue.size() >= fifo_size) begin
	    `uvm_fatal(this.get_name(), "result queue overflow! too many unhandled results!");
	    irq_result_fifo.lock.put(1);
	    return;
	 end
	 irq_result_fifo.queue.push_back(result);
	 irq_result_fifo.lock.put(1);
	 `uvm_info(this.get_name(), "generated a result!",UVM_HIGH);
      end
   endtask

   //default timeout:100ms
   task get_irq_result(output jvs_irq_result_trans tr, input int timeout = 100000000, input int polling_period = 100);
      int timer_cnt;
      do begin
	 irq_result_fifo.lock.get(1);
	 if (irq_result_fifo.queue.size() > 0) begin
	    tr = irq_result_fifo.queue.pop_front();
	    irq_result_fifo.lock.put(1);
	    `uvm_info(this.get_name(), "got a result!", UVM_HIGH);
	    return;
	 end
	 irq_result_fifo.lock.put(1);
	 timer_cnt += polling_period;
	 #(polling_period * 1ns);
      end while(timer_cnt <= timeout); // UNMATCHED !!
      `uvm_info(this.get_name(), "getting result timeout!", UVM_HIGH);
   endtask // get_irq_result

   task get_n_irq_results(int n, ref jvs_irq_result_trans tr_q[$], input int timeout = 100000000, input int polling_period = 100);
      int timer_cnt;
      int tr_cnt = n;
      do begin
	 int remain_tr_num;
	 int _tr_cnt;
	 irq_result_fifo.lock.get(1);
	 remain_tr_num = irq_result_fifo.queue.size();
	 _tr_cnt = tr_cnt < remain_tr_num ? tr_cnt : remain_tr_num;
	 for (int i = 0; i < _tr_cnt; i++) begin
	    tr_q.push_back(irq_result_fifo.queue.pop_front());
	 end
	 tr_cnt -= _tr_cnt;
	 irq_result_fifo.lock.put(1);
	 if (tr_cnt == 0) begin
	    `uvm_info(this.get_name(), $psprintf("got %0d results!", n), UVM_HIGH);
	    return;
	 end
	 timer_cnt += polling_period;
	 #(polling_period * 1ns);
      end while (timer_cnt <= timeout); // UNMATCHED !!
      `uvm_info(this.get_name(), $psprintf("getting %0d results timeout! got %0d results finally!", n, n - tr_cnt), UVM_HIGH);      
   endtask
endclass

`endif