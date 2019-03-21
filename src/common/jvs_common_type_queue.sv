`ifndef __JVS_COMMON_TYPE_QUEUE_SV__
 `define __JVS_COMMON_TYPE_QUEUE_SV__
class jvs_common_type_queue#(type T);
   T queue[$];
   semaphore lock;
   function new();
      lock = new(1);
   endfunction
endclass
`endif