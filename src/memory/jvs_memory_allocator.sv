`ifndef __JVS_MEMORY_ALLOCATOR_SV__
`define __JVS_MEMORY_ALLOCATOR_SV__

typedef jvs_common_attr jvs_memory_attr;
typedef class jvs_memory_block;
typedef class jvs_memory_free_block;
typedef class jvs_memory_acc_block;
   
   
class jvs_memory_range extends jvs_memory_block;
   `uvm_object_utils_begin(jvs_memory_range)
   `uvm_object_utils_end
   function new(input string name = "jvs_memory_range");
      super.new(name);
      this.size = 64'hffffffff_ffffffff;
   endfunction // new
endclass

virtual class jvs_memory_mmu extends uvm_object;
   `uvm_field_utils_begin(jvs_memory_mmu)
   `uvm_field_utils_end

   function new(input string name = "jvs_memory_mmu");
      super.new(name);
   endfunction // new

   pure virtual function bit[63:0] va2pa(bit[63:0] va, jvs_memory_attr attr);
   pure virtual function bit[63:0] pa2va(bit[63:0] pa, jvs_memory_attr attr);
   
endclass

class jvs_memory_cfg extends uvm_object;
   jvs_memory_mmu mmu;

   jvs_memory_range range;
   
   jvs_memory_model model;

   jvs_memory_attr attr;

   `uvm_object_utils_begin(jvs_memory_cfg)
     `uvm_field_object(range, UVM_ALL_ON | UVM_REFERENCE)
     `uvm_field_object(model, UVM_ALL_ON | UVM_REFERENCE)
     `uvm_field_object(mmu, UVM_ALL_ON | UVM_REFERENCE)
     `uvm_field_object(attr, UVM_ALL_ON | UVM_REFERENCE)
   `uvm_object_utils_end

   function new(input string name = "jvs_memory_cfg");
      super.new(name);
   endfunction // new

endclass


class jvs_memory_allocator extends jvs_memory_cfg;
   protected semaphore mutex;

   protected jvs_memory_block alloc_q[$];
   protected jvs_memory_free_block free_q[$];
   
   `uvm_object_utils_begin(jvs_memory_allocator)
     `uvm_field_queue_object(alloc_q, UVM_ALL_ON)
     `uvm_field_queue_object(free_q, UVM_ALL_ON)
   `uvm_object_utils_end

   function new(input string name = "jvs_memory_allocator");
      super.new(name);
      mutex = new(1);
   endfunction // new

   function void configurate(input jvs_memory_cfg cfg);
      jvs_memory_free_block free_range = jvs_memory_free_block::type_id::create();
      if (cfg == null) begin
	 `uvm_fatal(this.get_name(), "jvs_memory_cfg is null!");
      end
      if (cfg.range == null) begin
	 `uvm_fatal(this.get_name(), "range of jvs_memory_cfg is null!");
      end
      this.copy(cfg);
      free_range.configurate(range.get_s_addr(), range.get_size());
      this.free_q.push_back(free_range);
   endfunction

   local function bit alloc(input bit[63:0] size, input e_alignment align = ALIGN_BYTE, input jvs_memory_block output_block, input bit[64:0] s_addr = `JVS_MEM_NULL);
      jvs_memory_free_block lower_block, upper_block;
      foreach (this.free_q[i]) begin
	 if (this.free_q[i].gen_block(size, align, output_block, lower_block, upper_block, s_addr)) begin
	    this.alloc_q.push_back(output_block);
	    this.free_q.delete(i);
	    if (lower_block) begin
	       this.free_q.push_back(lower_block);
	    end
	    if (upper_block) begin
	       this.free_q.push_back(upper_block);
	    end

	    if (s_addr != `JVS_MEM_NULL && s_addr[63:0] != output_block.get_s_addr()) begin
	       `uvm_fatal(this.get_name(), $psprintf("fixed address alloc failed! req addr = 0x%0x, but get_addr = 0x%0x", s_addr, output_block.get_s_addr()))
	    end
	    return 1;
	 end // if (this.free_q[i].gen_block(size, align, output_block, lower_block, upper_block, s_addr))
      end
      return 0;
   endfunction // alloc

   task malloc(ref jvs_memory_acc_block acc_block, input bit[63:0] size, input e_alignment align = ALIGN_BYTE, input bit[64:0] s_addr = `JVS_MEM_NULL);
      mutex.get();
      begin
	 jvs_memory_acc_block _acc_block = jvs_memory_acc_block::type_id::create();
	 if (!this.alloc(size, align, _acc_block, s_addr)) begin
	    `uvm_info(this.get_name(), $psprintf("malloc failed! out of memory! size = 0x%0s", size), UVM_LOW);
	    acc_block = null;
	    mutex.put();
	    return;
	 end
	 _acc_block.set_p_allocator(this);
	 `uvm_info(this.get_name(), $psprintf("malloc success! \n%s", _acc_block.sprint()), UVM_HIGH);
	 acc_block = _acc_block;
      end
      mutex.put();
   endtask // malloc

   task free(ref jvs_memory_acc_block acc_block);
      mutex.get();
      begin
	 int alloc_block_index[$];
	 int lower_block_index_in_free_q[$];
	 int upper_block_index_in_free_q[$];
	 int lower_block_index_in_alloc_q[$];
	 int upper_block_index_in_alloc_q[$];
	 jvs_memory_block lower_block, upper_block;
	 jvs_memory_free_block free_block;

	 alloc_block_index = this.alloc_q.find_first_index with (item.get_s_addr() == acc_block.get_s_addr());

	 if (!alloc_block_index.size()) begin
	    acc_block.print();
	    `uvm_fatal(this.get_name(), "free failed! the memory block is not malloced!");
	    mutex.put();
	    return;
	 end

	 this.alloc_q.delete(alloc_block_index[0]);

	 if (!this.free_q.size()) begin
	    free_block = jvs_memory_free_block::type_id::create();
	    free_block.configurate(acc_block.get_s_addr(), acc_block.get_size());
	 end
	 else begin
	    lower_block_index_in_free_q = this.free_q.find_first_index with (item.get_e_addr() == acc_block.get_s_addr() - 1);
	    if (!lower_block_index_in_free_q.size()) begin
	       lower_block_index_in_alloc_q = this.alloc_q.find_first_index with (item.get_e_addr() == acc_block.get_s_addr() - 1);
	       if (lower_block_index_in_alloc_q.size()) begin
		  lower_block = this.alloc_q[lower_block_index_in_alloc_q[0]];
	       end
	    end
	    else begin
	       lower_block = this.free_q[lower_block_index_in_free_q[0]];
	       this.free_q.delete(lower_block_index_in_free_q[0]);
	    end

	    upper_block_index_in_free_q = this.free_q.find_first_index with (item.get_s_addr() == acc_block.get_e_addr() + 1);
	    if (!upper_block_index_in_free_q.size()) begin
	       upper_block_index_in_alloc_q = this.alloc_q.find_first_index with (item.get_s_addr() == acc_block.get_e_addr() + 1);
	       if (upper_block_index_in_alloc_q.size()) begin
		  upper_block = this.alloc_q[upper_block_index_in_alloc_q[0]];
	       end
	    end
	    else begin
	       upper_block = this.free_q[upper_block_index_in_free_q[0]];
	       this.free_q.delete(upper_block_index_in_free_q[0]);
	    end

	    if (!lower_block && !upper_block) begin
	       acc_block.print();
	       `uvm_fatal(this.get_name(), "free failed! can't find continuous block lower or upper block!");
	       mutex.put();
	       return;
	    end

	    free_block = jvs_memory_free_block::type_id::create();
	    if (lower_block) begin
	       jvs_memory_free_block lower_free_block;
	       if ($cast(lower_free_block, lower_block)) begin
		  free_block.configurate(lower_block.get_s_addr(), lower_block.get_size() + acc_block.get_size());
	       end
	       else begin
		  free_block.configurate(lower_block.get_s_addr(), acc_block.get_size());		  
	       end
	    end
	    else begin
	       free_block.configurate(lower_block.get_s_addr(), acc_block.get_size());		  
	    end

	    if (upper_block) begin
	       jvs_memory_free_block upper_free_block;
	       if ($cast(upper_free_block, upper_block)) begin
		  free_block.configurate(free_block.get_s_addr(), free_block.get_size() + upper_block.get_size());
	       end
	    end
	 end
	 this.free_q.push_back(free_block);
	 delete(acc_block);
	 acc_block = null;
      end
      mutex.put();
   endtask

   function bit[63:0] va2pa(bit[63:0] va);
      if (this.mmu == null) begin
	 return va;
      end
      return mmu.va2pa(va, this.attr);
   endfunction

   function bit[63:0] pa2va(bit[63:0] pa);
      if (this.mmu == null) begin
	 return pa;
      end
      return mmu.pa2va(pa, this.attr);
   endfunction

   function void write_long(bit[63:0] va, MEM_LONG data);
      `uvm_info(this.get_name(), $psprintf("write long begin: 0x%0x @(addr 0x%0x -> 0x%0x)", data, va, this.va2pa(va)), UVM_HIGH);
      this.model.write_long(this.va2pa(va), data);
      `uvm_info(this.get_name(), $psprintf("write long done: 0x%0x @(addr 0x%0x -> 0x%0x)", data, va, this.va2pa(va)), UVM_HIGH);
   endfunction

   function void write_int(bit[63:0] va, MEM_INT data);
      `uvm_info(this.get_name(), $psprintf("write int begin: 0x%0x @(addr 0x%0x -> 0x%0x)", data, va, this.va2pa(va)), UVM_HIGH);
      this.model.write_int(this.va2pa(va), data);
      `uvm_info(this.get_name(), $psprintf("write int done: 0x%0x @(addr 0x%0x -> 0x%0x)", data, va, this.va2pa(va)), UVM_HIGH);
   endfunction

   function void write_byte(bit[63:0] va, MEM_BYTE data);
      `uvm_info(this.get_name(), $psprintf("write byte begin: 0x%0x @(addr 0x%0x -> 0x%0x)", data, va, this.va2pa(va)), UVM_HIGH);
      this.model.write_byte(this.va2pa(va), data);
      `uvm_info(this.get_name(), $psprintf("write byte done: 0x%0x @(addr 0x%0x -> 0x%0x)", data, va, this.va2pa(va)), UVM_HIGH);
   endfunction
 
   function MEM_LONG read_long(bit[63:0] va);
      MEM_LONG data;
      `uvm_info(this.get_name(), $psprintf("read long begin: @(addr 0x%0x -> 0x%0x)", va, this.va2pa(va)), UVM_HIGH);
      data = this.model.read_long(this.va2pa(va));
      `uvm_info(this.get_name(), $psprintf("read long done: 0x%0x @(addr 0x%0x -> 0x%0x)", data, va, this.va2pa(va)), UVM_HIGH);
      return data;
   endfunction

   function MEM_INT read_int(bit[63:0] va);
      MEM_INT data;
      `uvm_info(this.get_name(), $psprintf("read int begin: @(addr 0x%0x -> 0x%0x)", va, this.va2pa(va)), UVM_HIGH);
      data = this.model.read_int(this.va2pa(va));
      `uvm_info(this.get_name(), $psprintf("read int done: 0x%0x @(addr 0x%0x -> 0x%0x)", data, va, this.va2pa(va)), UVM_HIGH);
      return data;
   endfunction

   function MEM_BYTE read_byte(bit[63:0] va);
      MEM_BYTE data;
      `uvm_info(this.get_name(), $psprintf("read byte begin: @(addr 0x%0x -> 0x%0x)", va, this.va2pa(va)), UVM_HIGH);
      data = this.model.read_byte(this.va2pa(va));
      `uvm_info(this.get_name(), $psprintf("read byte done: 0x%0x @(addr 0x%0x -> 0x%0x)", data, va, this.va2pa(va)), UVM_HIGH);
      return data;
   endfunction

   function void delete(jvs_memory_acc_block acc_block);
      if (acc_block.get_p_allocator != this) begin
	 acc_block.print();
	 `uvm_fatal(this.get_name(), "can not delete block is not allocated for this allocator!");
      end
      `uvm_info(this.get_name(), $psprintf("delete begin: @(addr 0x%0x -> 0x%0x) to @(addr 0x%0x -> 0x%0x)", acc_block.get_s_addr(), this.va2pa(acc_block.get_s_addr()), acc_block.get_e_addr(), this.va2pa(acc_block.get_e_addr())), UVM_HIGH);
      this.model.delete(this.va2pa(acc_block.get_s_addr()), acc_block.get_size());
      `uvm_info(this.get_name(), $psprintf("delete done: @(addr 0x%0x -> 0x%0x) to @(addr 0x%0x -> 0x%0x)", acc_block.get_s_addr(), this.va2pa(acc_block.get_s_addr()), acc_block.get_e_addr(), this.va2pa(acc_block.get_e_addr())), UVM_HIGH);
      
   endfunction
 
   function bit[63:0] memcopy(jvs_memory_acc_block src_acc_block, jvs_memory_acc_block dst_acc_block);
      bit[63:0] size; 
      if (src_acc_block.get_p_allocator != this) begin
	 src_acc_block.print();
	 `uvm_fatal(this.get_name(), "can not copy block is not allocated for this allocator!");
      end
      if (dst_acc_block.get_p_allocator != this) begin
	 dst_acc_block.print();
	 `uvm_fatal(this.get_name(), "can not copy block is not allocated for this allocator!");
      end
      size = src_acc_block.get_size() < dst_acc_block.get_size() ? src_acc_block.get_size() : dst_acc_block.get_size();
      `uvm_info(this.get_name(), $psprintf("copy size %0d begin: @(addr 0x%0x -> 0x%0x) to @(addr 0x%0x -> 0x%0x)", size, src_acc_block.get_s_addr(), this.va2pa(src_acc_block.get_s_addr()), dst_acc_block.get_s_addr(), this.va2pa(dst_acc_block.get_s_addr())), UVM_HIGH);
      for (int i = 0; i < size; i++) begin
	 this.model.write_byte(this.va2pa(dst_acc_block.get_s_addr()) + i, this.model.read_byte(this.va2pa(src_acc_block.get_s_addr()) + i));
      end
      `uvm_info(this.get_name(), $psprintf("copy size %0d done: @(addr 0x%0x -> 0x%0x) to @(addr 0x%0x -> 0x%0x)", size, src_acc_block.get_s_addr(), this.va2pa(src_acc_block.get_s_addr()), dst_acc_block.get_s_addr(), this.va2pa(dst_acc_block.get_s_addr())), UVM_HIGH);
      return size;
   endfunction


endclass

`endif