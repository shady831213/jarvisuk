`ifndef __JVS_COMMON_CONDITION_SV__
 `define __JVS_COMMON_CONDITION_SV__
class jvs_common_condition;
   local semaphore lock;
   local semaphore wait_queue[$];
   
   function new(semaphore lock);
      this.lock = lock;      
   endfunction
		   
   task sleep();
      semaphore waiter = new(0);
      wait_queue.push_back(waiter);
      lock.put(1);
      waiter.get(1);
      lock.get(1);
   endtask // sleep

   task wake();
      if (wait_queue.size()!=0) begin
	 semaphore nxt_w = wait_queue.pop_front();
	 nxt_w.put(1);
      end
   endtask // wake

   task wake_all();
      while(wait_queue.size()!=0) begin
	 wake();
      end
   endtask
endclass
`endif