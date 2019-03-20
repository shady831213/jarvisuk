`ifndef __JVS_MEMORY_BLOCK_SV__
 `define __JVS_MEMORY_BLOCK_SV__
typedef class jvs_memory_model;
typedef class jvs_memory_allocator;

virtual class jvs_memory_block extends uvm_object;
   rand protected bit[63:0] s_addr;
   rand protected bit[63:0] size;
   `uvm_field_utils_begin(jvs_memory_block)
     `uvm_field_int(s_addr, UVM_ALL_ON)
     `uvm_field_int(size, UVM_ALL_ON)
   `uvm_field_utils_end

   function new(input string name = "jvs_memory_block");
      super.new(name);
   endfunction // new

   function bit[63:0] get_s_addr();
      return this.s_addr;
   endfunction // get_s_addr

   function bit[64:0] get_size();
      return this.size + 1;
   endfunction

   function bit[63:0] get_e_addr();
      return this.s_addr + this.size;
   endfunction

   function bit[1:0] check_boundary(input bit[63:0] addr, input bit[63:0] size = 1);
      bit uf = addr < this.s_addr;
      bit of = addr + size - 1 > this.get_e_addr();
      return {uf, of};
   endfunction // check_boundary

   function void configurate(input bit[63:0] s_addr, input bit[64:0] size);
      this.s_addr = s_addr;
      this.size = size - 1;
   endfunction
endclass // jvs_memory_block

class jvs_memory_free_block extends jvs_memory_block;
   `uvm_object_utils_begin(jvs_memory_free_block)
   `uvm_object_utils_end

   function new(input string name = "jvs_memory_free_block");
      super.new(name);
   endfunction

   local function bit[63:0] get_align_s_addr(input e_alignment align);
      bit [63:0] _s_addr = this.s_addr + ((1<<align) - 1);
      foreach (_s_addr[i]) begin
	 if (i < align) begin
	    _s_addr[i] = 0;
	 end
      end
      return _s_addr;
   endfunction // get_align_s_addr

   function bit gen_block(input bit[63:0] size_req,
			  input e_alignment align,
			  jvs_memory_block output_block,
			  output jvs_memory_free_block lower_block,
			  output jvs_memory_free_block upper_block,
			  input bit[64:0] s_addr_req = `JVS_MEM_NULL);
      bit [63:0] 			  s_addr_aligned;
      bit [64:0] 			  e_addr_req;
      bit 				  fixed_s_addr = s_addr_req != `JVS_MEM_NULL;
      if (fixed_s_addr) begin
	 s_addr_aligned = s_addr_req[63:0];
      end
      else begin
	 s_addr_aligned = this.get_align_s_addr(align);
      end
      e_addr_req = s_addr_aligned + size_req - 1;

      if (e_addr_req > this.get_e_addr() || 
	  e_addr_req < this.get_s_addr() || 
	  s_addr_aligned > this.get_e_addr() ||
	  s_addr_aligned < this.get_s_addr() ||
	  e_addr_req[64]) begin
	 return 0;
      end

      begin
	 bit [63:0] _s_addr = s_addr_aligned;
	 bit [63:0] _e_addr = this.get_e_addr();
	 bit [63:0] _size = size_req;

	 if (fixed_s_addr) begin
	    assert(output_block.randomize() with {
						  s_addr == _s_addr;
						  size == _size - 1;
						  s_addr + size inside {[_s_addr : _e_addr]};
						  }) else begin
	       `uvm_fatal(this.get_name(), "gen_block failed!");
	    end
         end
	 else begin
	    bit[63:0] _output_block_s_addr;
	    assert(output_block.randomize() with {
						  s_addr inside {[_s_addr : _e_addr]};
						  size == _size - 1;
						  s_addr + size inside {[_s_addr : _e_addr]};						  
						  }) else begin
	       `uvm_fatal(this.get_name(), "gen_block failed!");
	    end
            _output_block_s_addr = output_block.get_s_addr();
            foreach(_output_block_s_addr[i]) begin
	       if (i < align) begin
		  _output_block_s_addr[i] = 0;
	       end
	    end
            output_block.configurate(_output_block_s_addr, output_block.get_size());
         end // else: !if(fixed_s_addr)

	 
	 if (this.get_s_addr() != output_block.get_s_addr()) begin
	    jvs_memory_free_block _lower_block = jvs_memory_free_block::type_id::create();
	    _lower_block.configurate(this.get_s_addr(), output_block.get_s_addr() - this.get_s_addr());
	    lower_block = _lower_block;
	 end
	 else begin
	    lower_block = null;
	 end

	 if (_e_addr != output_block.get_e_addr()) begin
	    jvs_memory_free_block _upper_block = jvs_memory_free_block::type_id::create();
	    _upper_block.configurate(output_block.get_e_addr() + 1, _e_addr - output_block.get_e_addr());
	    upper_block = _upper_block;
	 end
	 else begin
	    upper_block = null;
	 end
      end // begin
      return 1;
   endfunction

endclass // jvs_memory_free_block


class jvs_memory_acc_block extends jvs_memory_block;
   protected jvs_memory_allocator p_allocator;
   `uvm_object_utils_begin(jvs_memory_acc_block)
     `uvm_field_object(p_allocator, UVM_ALL_ON)
   `uvm_object_utils_end

   function new(input string name = "jvs_memory_acc_block");
      super.new(name);
   endfunction
  
   function void set_p_allocator(jvs_memory_allocator p_allocator);
      this.p_allocator = p_allocator;
   endfunction // set_p_allocator

   function jvs_memory_allocator get_p_allocator();
      return this.p_allocator;
   endfunction // set_p_allocator


   local function void check_before_access(input bit[63:0] addr, input bit[63:0] size_req = 1);
      bit[1:0] status;
      status = check_boundary(addr, size_req);
      if (status[1]) begin
	 `uvm_fatal(this.get_name(), $psprintf("addr 0x%0x is underflow! s_addr is 0x%0x", addr, s_addr));
      end
      if (status[0]) begin
	 `uvm_fatal(this.get_name(), $psprintf("addr 0x%0x is overflow! s_addr is 0x%0x", addr, this.get_e_addr));
      end
   endfunction
   
   function void write_long(input bit[63:0] addr, input MEM_LONG data);
      check_before_access(s_addr + addr, 8);
      this.p_allocator.write_long(s_addr+addr, data);
   endfunction

   function void write_int(input bit[63:0] addr, input MEM_INT data);
      check_before_access(s_addr + addr, 4);
      this.p_allocator.write_int(s_addr+addr, data);
   endfunction

   function void write_byte(input bit[63:0] addr, input MEM_BYTE data);
      check_before_access(s_addr + addr, 1);
      this.p_allocator.write_byte(s_addr+addr, data);
   endfunction

   function MEM_LONG read_long(input bit[63:0] addr);
      check_before_access(s_addr + addr, 8);
      return this.p_allocator.read_long(s_addr+addr);
   endfunction

   function MEM_INT read_int(input bit[63:0] addr);
      check_before_access(s_addr + addr, 4);
      return this.p_allocator.read_int(s_addr+addr);
   endfunction

   function MEM_BYTE read_byte(input bit[63:0] addr);
      check_before_access(s_addr + addr, 1);
      return this.p_allocator.read_byte(s_addr+addr);
   endfunction

   function void data2mem(input MEM_BYTE data[], input bit[63:0] offset = 0);
      foreach(data[i]) begin
	 write_byte(offset + i, data[i]);
      end
   endfunction

   function void data2mem_stream(uvm_bitstream_t value, input int size_req, input bit[63:0] offset = 0);
      if ((size_req % 8) != 0) begin
	 `uvm_fatal(this.get_name(), $psprintf("mem2data_stream size %0d is not byte aligned!", size_req));
      end
      if (size_req > `UVM_MAX_STREAMBITS) begin
	 `uvm_fatal(this.get_name(), $psprintf("mem2data_stream size %0d is larger than UVM_MAX_STREAMBITS %0d!", size_req, `UVM_MAX_STREAMBITS));
      end

      for(int i = 0; i < (size_req/8); i++) begin
	 write_byte(offset+i, value[i*8 +:8]);
      end
   endfunction


   function void mem2data(ref MEM_BYTE data[], input bit[63:0] offset = 0);
      data = new[this.get_size() -offset];
      foreach(data[i]) begin
	 data[i] = read_byte(offset + i);
      end
   endfunction

   function void mem2data_stream(output uvm_bitstream_t value, input int size_req, input bit[63:0] offset = 0);
      if ((size_req % 8) != 0) begin
	 `uvm_fatal(this.get_name(), $psprintf("mem2data_stream size %0d is not byte aligned!", size_req));
      end
      if (size_req > `UVM_MAX_STREAMBITS) begin
	 `uvm_fatal(this.get_name(), $psprintf("mem2data_stream size %0d is larger than UVM_MAX_STREAMBITS %0d!", size_req, `UVM_MAX_STREAMBITS));
      end
      for(int i = 0; i < (size_req/8); i++) begin
	 value[i*8 +:8] = read_byte(offset+i);
      end
   endfunction
   
endclass   
`endif