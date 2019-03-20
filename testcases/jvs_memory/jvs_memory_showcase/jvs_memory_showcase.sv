`ifndef __JVS_MEMORY_SHOWCASE_SV__
 `define __JVS_MEMORY_SHOWCASE_SV__
class jvs_memory_showcase_component extends uvm_component;
   jvs_memory_allocator allocator;
   jvs_memory_acc_block share_acc_block;

   `uvm_component_utils_begin(jvs_memory_showcase_component)
   `uvm_component_utils_end

   function new(string name="jvs_memory_showcase_component", uvm_component parent = null);
      super.new(name, parent);
   endfunction // new

   task write_case1();
      jvs_memory_acc_block acc_block;
      allocator.malloc(acc_block, 1, ALIGN_BYTE, 65'b1);
      acc_block.write_byte(64'b0, 8'h5a);
   endtask // write_case1

   task read_case1();
      jvs_memory_acc_block acc_block;
      MEM_BYTE data;
      allocator.malloc(acc_block, 1, ALIGN_BYTE, 65'b1);
      data = acc_block.read_byte(64'b0);
      if (data != 8'h5a) begin
	 `uvm_error(this.get_name(), $psprintf("read_case1: data expect 0x5a data is 0x%0x", data));
	 return;
      end
      `uvm_info(this.get_name(), $psprintf("read_case1: data expect 0x5a data is 0x%0x", data), UVM_LOW);
   endtask

   task write_case2();
      jvs_memory_model model = allocator.model;
      model.write_byte(64'h10, 8'ha5);
   endtask


   task read_case2();
      jvs_memory_acc_block acc_block;
      MEM_BYTE data;
      allocator.malloc(acc_block, 10, ALIGN_BYTE, 65'h10);
      acc_block.print();
      data = acc_block.read_byte(64'h0);
      if (data != 8'ha5) begin
	 `uvm_error(this.get_name(), $psprintf("read_case2: data expect 0xa5 data is 0x%0x", data));
	 return;
      end
      `uvm_info(this.get_name(), $psprintf("read_case2: data expect 0xa5 data is 0x%0x", data), UVM_LOW);      
   endtask


   task write_case3();
      MEM_BARRAY array;
      array = new[share_acc_block.get_size()];
      foreach(array[i]) begin
	 array[i] = i;
      end
      share_acc_block.data2mem(array);
   endtask // write_case1

   task read_case3();
      MEM_BARRAY array;
      share_acc_block.mem2data(array);
      `uvm_info(this.get_name(), $psprintf("read_case3: array size is %0d", array.size()), UVM_LOW);
      foreach(array[i]) begin
	 if (array[i] != i) begin
	    `uvm_error(this.get_name(), $psprintf("read_case3: array[%0d] expect %0d data is %0d", i, i, array[i]));
	    return;
	 end
	 `uvm_info(this.get_name(), $psprintf("read_case3: array[%0d] expect %0d data is %0d", i, i, array[i]), UVM_LOW);
      end
   endtask

endclass


class jvs_memory_showcase_cfg extends jvs_memory_cfg;
   `uvm_object_utils_begin(jvs_memory_showcase_cfg)
   `uvm_object_utils_end
   function new(string name="jvs_memory_showcase_cfg");
      super.new(name);
      this.range = jvs_memory_range::type_id::create();
      this.model = jvs_memory_aa_model::type_id::create("model");
   endfunction // new

endclass

class jvs_memory_showcase extends uvm_test;
   jvs_memory_showcase_cfg cfg;
   jvs_memory_allocator allocator1;
   jvs_memory_allocator allocator2;
   jvs_memory_allocator allocator3;

   jvs_memory_showcase_component producer;
   jvs_memory_showcase_component consumer;
   
   
   `uvm_component_utils_begin(jvs_memory_showcase)
   `uvm_component_utils_end

   function new(string name="jvs_memory_showcase", uvm_component parent = null);
      super.new(name, parent);
   endfunction // new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cfg = jvs_memory_showcase_cfg::type_id::create("cfg");
   
      //individual allocator, for case1&case2
      allocator1 = jvs_memory_allocator::type_id::create("allocator1");
      allocator1.configurate(cfg);
      allocator2 = jvs_memory_allocator::type_id::create("allocator2");
      allocator2.configurate(cfg);
      //share allocator, for case3
      allocator3 = jvs_memory_allocator::type_id::create("allocator3");
      allocator3.configurate(cfg);
     
      producer = jvs_memory_showcase_component::type_id::create("producer", this);
      consumer = jvs_memory_showcase_component::type_id::create("consumer", this);
      producer.allocator = allocator1;
      consumer.allocator = allocator3;
   
   endfunction // build_phase

   task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      super.run_phase(phase);
      //case1
      producer.write_case1();
      consumer.read_case1();
      //case2
      producer.write_case2();
      consumer.read_case2();
      //case3
      allocator3.malloc(producer.share_acc_block, 9, ALIGN_BYTE);
      consumer.share_acc_block = producer.share_acc_block;
      producer.write_case3();
      consumer.read_case3();
      phase.drop_objection(this);
   endtask
endclass

`endif