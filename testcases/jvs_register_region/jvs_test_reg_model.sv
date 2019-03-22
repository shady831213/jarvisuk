`ifndef __JVS_TEST_REG_MODEL_SV__
 `define __JVS_TEST_REG_MODEL_SV__
class jvs_test_reg extends uvm_reg;
   `uvm_object_utils(jvs_test_reg)
   rand uvm_reg_field test_field;
   function new(string name = "jvs_test_reg");
      super.new(name, 32, (UVM_NO_COVERAGE));
   endfunction // new

   virtual function void build();
      this.test_field = uvm_reg_field::type_id::create("test_field",, get_full_name());
      this.test_field.configure(this, 32, 0, "RW", 0, 32'b0, 1, 1, 1);
   endfunction
endclass // jvs_test_reg

class jvs_test_block extends uvm_reg_block;
   `uvm_object_utils(jvs_test_block)
   rand jvs_test_reg test_reg;

   function new(string name = "jvs_test_block");
      super.new(name,(UVM_NO_COVERAGE));
   endfunction // new

   virtual function void build();
      this.default_map = create_map("", 0, 4, UVM_LITTLE_ENDIAN, 0);
      this.test_reg = jvs_test_reg::type_id::create("test_reg",, get_full_name());
      this.test_reg.configure(this, null, "");
      this.test_reg.build();
      this.default_map.add_reg(this.test_reg, `UVM_REG_ADDR_WIDTH'h4, "RW", 0);
   endfunction
   
endclass // jvs_test_block

class jvs_test_sub_top_block extends uvm_reg_block;
   rand jvs_test_block block[2];
   
   `uvm_object_utils(jvs_test_sub_top_block)
   function new(string name = "jvs_test_sub_top_block");
      super.new(name);
   endfunction // new

   virtual function void build();
      this.default_map = create_map("", 0, 4, UVM_LITTLE_ENDIAN, 0);
      foreach(this.block[i]) begin
	 this.block[i] = jvs_test_block::type_id::create($psprintf("block[%0d]", i));
	 this.block[i].configure(this);
	 this.block[i].build();
	 this.default_map.add_submap(this.block[i].default_map, i << 16);
      end
   endfunction

endclass

class jvs_test_top_block extends uvm_reg_block;
   rand jvs_test_sub_top_block sub_top_block;
   rand jvs_test_block block[2];
   rand jvs_test_reg test_reg;
   
   `uvm_object_utils(jvs_test_top_block)
   function new(string name = "jvs_test_top_block");
      super.new(name);
   endfunction // new

   virtual function void build();
      this.default_map = create_map("", 0, 4, UVM_LITTLE_ENDIAN, 0);
      foreach(this.block[i]) begin
	 this.block[i] = jvs_test_block::type_id::create($psprintf("block[%0d]", i));
	 this.block[i].configure(this);
	 this.block[i].build();
	 this.default_map.add_submap(this.block[i].default_map, i << 24);
      end
   
      this.sub_top_block = jvs_test_sub_top_block::type_id::create("sub_top_block");
      this.sub_top_block.configure(this);
      this.sub_top_block.build();
      this.default_map.add_submap(this.sub_top_block.default_map, 3 << 24);
   
      this.test_reg = jvs_test_reg::type_id::create("top_reg",, get_full_name());
      this.test_reg.configure(this, null, "");
      this.test_reg.build();
      this.default_map.add_reg(this.test_reg, 4 << 24, "RW", 0);
   endfunction

endclass
`endif