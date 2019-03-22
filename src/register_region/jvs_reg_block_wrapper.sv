`ifndef  __JVS_REG_BLOCK_WRAPPER_SV__
 `define  __JVS_REG_BLOCK_WRAPPER_SV__
typedef class jvs_reg_region;
class jvs_reg_block_wrapper extends jvs_reg_tree_node#(jvs_reg_region);
   protected uvm_reg_block reg_block;
   `uvm_object_utils_begin(jvs_reg_block_wrapper)
   `uvm_object_utils_end

   function new(string name = "jvs_reg_block_wrapper");
      super.new(name);
   endfunction // new

   function void bind_reg_block(uvm_reg_block reg_block);
      this.reg_block = reg_block;
   endfunction // bind_reg_block

   virtual function bit[63:0] get_base();
      return reg_block.get_default_map().get_base_addr();
   endfunction // get_base

   virtual function bit[63:0] get_size();
      return reg_block.get_default_map().get_size();
   endfunction
   
   function jvs_reg_block_wrapper get_reg_block(string name);
      uvm_reg_block block = reg_block.get_block_by_name(name);
      jvs_reg_block_wrapper wrapper = jvs_reg_block_wrapper::type_id::create(name);
      wrapper.parent = this.parent;
      wrapper.bind_reg_block(block);
      return wrapper;
   endfunction // get_reg_block

   function bit get_reg(string name, output jvs_reg_block_wrapper reg_block, output uvm_reg register);
      uvm_reg _register = this.reg_block.get_reg_by_name(name);
      if (_register != null) begin
	 register = _register;
	 reg_block = this;
	 return 1;
      end
      return 0;
   endfunction // get_reg

   //for bit bash and reset value
   task request_access();
      jvs_reg_resource_manager::get_manager().request_reg_map(parent.get_seqr_adapter(), reg_block.get_default_map().get_root_map());
   endtask // request_access

   task release_access();
      jvs_reg_resource_manager::get_manager().release_reg_map(parent.get_seqr_adapter(), reg_block.get_default_map().get_root_map());
   endtask // release_access

   function uvm_reg_block get_uvm_reg_block();
      return this.reg_block;
   endfunction
endclass
`endif