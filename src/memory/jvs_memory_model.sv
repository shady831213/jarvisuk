`ifndef __JVS_MEMORY_MODEL_SV__
 `define __JVS_MEMORY_MODEL_SV__
virtual class jvs_memory_model extends uvm_object;
   `uvm_field_utils_begin(jvs_memory_model)
   `uvm_field_utils_end
   function new(input string name = "jvs_memory_model");
      super.new(name);
   endfunction // new
   pure virtual function void write_byte(input bit[63:0]addr, input MEM_BYTE data);
   pure virtual function MEM_BYTE read_byte(input bit[63:0]addr);
   
   virtual function void write_int(input bit[63:0]addr, input MEM_INT data);
      for(bit[2:0] i = 0; i < 4; i++) begin
	 write_byte({addr[63:2], i[1:0]}, data[i*8 +: 8]);
      end
   endfunction

   virtual function MEM_INT read_int(input bit[63:0]addr);
      MEM_INT data;
      for(bit[2:0] i = 0; i < 4; i++) begin
	 data[i*8 +: 8] = read_byte({addr[63:2], i[1:0]});
      end
      return data;
   endfunction

   virtual function void write_long(input bit[63:0]addr, input MEM_LONG data);
      for(bit[3:0] i = 0; i < 8; i++) begin
	 write_byte({addr[63:3], i[2:0]}, data[i*8 +: 8]);
      end
   endfunction

   virtual function MEM_LONG read_long(input bit[63:0]addr);
      MEM_LONG data;
      for(bit[3:0] i = 0; i < 8; i++) begin
	 data[i*8 +: 8] = read_byte({addr[63:3], i[2:0]});
      end
      return data;
   endfunction

   virtual function void delete(input bit[63:0] addr, input bit[63:0] size);
      for (bit[63:0] i = 0; i < size; i++) begin
	 write_byte(addr + i, 0);
      end
   endfunction
endclass

class jvs_memory_aa_model extends jvs_memory_model;
   protected MEM_BYTE mem[bit[63:0]];
   
   `uvm_object_utils_begin(jvs_memory_aa_model)
   `uvm_object_utils_end
   function new(input string name = "jvs_memory_aa_model");
      super.new(name);
   endfunction // new

   virtual function void write_byte(input bit[63:0]addr, input MEM_BYTE data);
      mem[addr] = data;
   endfunction // write_byte
   
   virtual function MEM_BYTE read_byte(input bit[63:0]addr);
      return mem[addr];
   endfunction

   virtual function void delete(input bit[63:0] addr, input bit[63:0] size);
      for (bit[63:0] i = 0; i < size; i++) begin
	 mem.delete(addr + i);
      end
   endfunction
   
endclass
`endif