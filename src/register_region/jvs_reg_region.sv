`ifndef __JVS_REG_REGION_SV__
 `define __JVS_REG_REGION_SV__
class jvs_reg_region_attr extends jvs_common_attr;
   `uvm_object_utils(jvs_reg_region_attr);
   function new(string name = "jvs_reg_region_attr");
      super.new(name);
   endfunction // new   
endclass // jvs_reg_region_attr

class jvs_reg_region extends jvs_reg_tree_node#(jvs_reg_region);
   typedef jvs_reg_tree_node#(jvs_reg_region) NODE_TYPE;
   rand jvs_reg_region_attr attr;
   local jvs_reg_seqr_adapter_pair seqr_adapter;
   protected jvs_reg_tree_nodes#(jvs_reg_block_wrapper) reg_block_table;
   protected jvs_reg_tree_nodes#(jvs_reg_region) sub_region_table;
   protected bit[63:0] offset;
   protected bit [63:0] size;

   `uvm_object_utils_begin(jvs_reg_region)
     `uvm_field_object(attr, UVM_ALL_ON)
     `uvm_field_object(seqr_adapter, UVM_ALL_ON)
     `uvm_field_object(reg_block_table, UVM_ALL_ON)
     `uvm_field_object(sub_region_table, UVM_ALL_ON)
     `uvm_field_int(offset, UVM_ALL_ON)
     `uvm_field_int(size, UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name = "jvs_reg_region");
      super.new(name);
      reg_block_table = jvs_reg_tree_nodes#(jvs_reg_block_wrapper)::type_id::create("reg_block_table");
      sub_region_table = jvs_reg_tree_nodes#(jvs_reg_region)::type_id::create("sub_region_table");
   endfunction // new

   virtual function bit[63:0] get_base();
      if (parent == null) begin
	 return offset;
      end
      return parent.get_base() + offset;
   endfunction // get_base

   virtual function bit[63:0] get_size();
      return size;
   endfunction // get_size

   function void config_range(bit[63:0] offset, bit[63:0] size);
      this.offset = offset;
      this.size =size;
   endfunction // config_range

   function void config_seqr_adapter(jvs_reg_seqr_adapter_pair seqr_adapter);
      this.seqr_adapter = seqr_adapter;
   endfunction // config_seqr_adapter

   //path compression
   function jvs_reg_seqr_adapter_pair get_seqr_adapter();
      if (this.seqr_adapter == null) begin
	 this.seqr_adapter = parent.get_seqr_adapter();
      end
      if (this.seqr_adapter == null) begin
	 `uvm_fatal(this.get_name(), "not set seqr_adapter!");
      end
      return this.seqr_adapter;
   endfunction // get_seqr_adapter

   function bit add_reg_block(jvs_reg_block_wrapper reg_block);
      jvs_reg_region sub_regions[$];
      jvs_reg_block_wrapper reg_blocks[$];
      //check if exist
      if (!reg_block_table.check_exist_name(reg_block)) begin
	 return 0;
      end
      reg_block_table.get_nodes(reg_blocks);
      sub_region_table.get_nodes(sub_regions);
      //if exists sub region, add to it
      foreach(sub_regions[i]) begin
	 if (reg_block.in_region(sub_regions[i])) begin
	    return sub_regions[i].add_reg_block(reg_block);
	 end
      end
      reg_block.set_parent(this);
      if (!check_in_region(reg_block)) begin
	 reg_block.set_parent(null);
	 return 0;
      end
      //if exist a reg_block is child of one another, use the one has larger range
      foreach(reg_blocks[i]) begin
	 if (reg_block.in_region(reg_blocks[i])) begin
	    return 1;
	 end
      end
      if (!reg_block_table.check_overlap(reg_block)) begin
	 reg_block.set_parent(null);
	 return 0;
      end
      reg_block_table.add_node(reg_block);
      return 1;
   endfunction // add_reg_block

   function bit add_sub_region(jvs_reg_region region);
      jvs_reg_region sub_regions[$];
      //check if exist
      if (!sub_region_table.check_exist_name(region))begin
	 return 0;
      end
      sub_region_table.get_nodes(sub_regions);
      //if existes sub region, add to it
      foreach(sub_regions[i]) begin
	 if (region.in_region(sub_regions[i])) begin
	    return sub_regions[i].add_sub_region(region);
	 end
      end
      region.set_parent(this);
      if (!check_in_region(region))begin
	 region.set_parent(null);
	 return 0;
      end
      if (!sub_region_table.check_overlap(region)) begin
	 region.set_parent(null);
	 return 0;
      end
      sub_region_table.add_node(region);
      return 1;
   endfunction // add_sub_region

   function jvs_reg_block_wrapper get_reg_block(string key);
      jvs_reg_region sub_regions[$];
      jvs_reg_block_wrapper reg_blocks[$];
      jvs_reg_block_wrapper reg_block;
      
      reg_block_table.get_nodes(reg_blocks);
      foreach(reg_blocks[i]) begin
	 reg_block = reg_blocks[i].get_reg_block(key);
	 if (reg_block!=null) begin
	    return reg_block;
	 end
      end
      sub_region_table.get_nodes(sub_regions);
      foreach(sub_regions[i]) begin
	 reg_block = sub_regions[i].get_reg_block(key);
	 if(reg_block != null) begin
	    return reg_block;
	 end
      end
      return null;
   endfunction // get_reg_block

   function bit remove_reg_block(string key);
      jvs_reg_region sub_regions[$];
      if (reg_block_table.remove_node(key)) begin
	 return 1;
      end
      sub_region_table.get_nodes(sub_regions);
      foreach(sub_regions[i]) begin
	 if (sub_regions[i].remove_reg_block(key)) begin
	    return 1;
	 end
      end
      return 0;
   endfunction // remove_reg_block

   local function bit get_reg(string name, output jvs_reg_block_wrapper reg_block, output uvm_reg register);
      jvs_reg_region sub_regions[$];
      jvs_reg_block_wrapper reg_blocks[$];
      jvs_reg_block_wrapper _reg_block;
      uvm_reg _register;
      sub_region_table.get_nodes(sub_regions);
      foreach(sub_regions[i]) begin
	 if (sub_regions[i].get_reg(name, _reg_block, _register)) begin
	    reg_block = _reg_block;
	    register = _register;
	    return 1;
	 end
      end
      reg_block_table.get_nodes(reg_blocks);
      foreach(reg_blocks[i]) begin
	 if(reg_blocks[i].get_reg(name, _reg_block, _register)) begin
	    reg_block = _reg_block;
	    register = _register;
	    return 1;
	 end
      end
      return 0;
   endfunction // get_reg

   function jvs_reg_region get_region(string key);
      if (key == this.get_name()) begin
	 return this;
      end
      return this.get_sub_region(key);
   endfunction
   
   function jvs_reg_region get_sub_region(string key);
      jvs_reg_region sub_regions[$];
      jvs_reg_region node = sub_region_table.get_node(key);
      if (node != null) begin
	 return node;
      end
      sub_region_table.get_nodes(sub_regions);
      foreach(sub_regions[i])begin
	 node = sub_regions[i].get_sub_region(key);
	 if (node != null) begin
	    return node;
	 end
      end
      return null;
   endfunction // get_sub_region

   //for normal case access
   local task write(string name, uvm_reg_data_t value, output uvm_status_e status, input uvm_path_e path = UVM_DEFAULT_PATH);
      uvm_reg match_reg;
      jvs_reg_block_wrapper reg_block;
      if (get_reg(name, reg_block, match_reg)) begin
	 `uvm_info(this.get_name(), "write begin request!", UVM_HIGH);
	 jvs_reg_resource_manager::get_manager().request_reg_map(get_seqr_adapter(), match_reg.get_default_map().get_root_map());
	 `uvm_info(this.get_name(), "begin write!", UVM_HIGH);
	 match_reg.write(.status(status), .value(value), .path(path), .extension(attr));
	 `uvm_info(this.get_name(), "after write!", UVM_HIGH);
	 jvs_reg_resource_manager::get_manager().release_reg_map(get_seqr_adapter(), match_reg.get_default_map().get_root_map());
	 `uvm_info(this.get_name(), "write after release!", UVM_HIGH);	 
      end
   endtask // write

   task write_fd(string name, uvm_reg_data_t value, output uvm_status_e status);
      this.write(name, value, status, UVM_FRONTDOOR);
   endtask

   task write_bd(string name, uvm_reg_data_t value, output uvm_status_e status);
      this.write(name, value, status, UVM_BACKDOOR);
   endtask // write_bd
 
  local task read(string name, output uvm_reg_data_t value, output uvm_status_e status, input uvm_path_e path = UVM_DEFAULT_PATH);
      uvm_reg match_reg;
      jvs_reg_block_wrapper reg_block;
      if (get_reg(name, reg_block, match_reg)) begin
	 `uvm_info(this.get_name(), "read begin request!", UVM_HIGH);
	 jvs_reg_resource_manager::get_manager().request_reg_map(get_seqr_adapter(), match_reg.get_default_map().get_root_map());
	 `uvm_info(this.get_name(), "begin read!", UVM_HIGH);
	 match_reg.read(.status(status), .value(value), .path(path), .extension(attr));
	 `uvm_info(this.get_name(), "after read!", UVM_HIGH);
	 jvs_reg_resource_manager::get_manager().release_reg_map(get_seqr_adapter(), match_reg.get_default_map().get_root_map());
	 `uvm_info(this.get_name(), "read after release!", UVM_HIGH);	 
      end
   endtask // read

   task read_fd(string name, output uvm_reg_data_t value, output uvm_status_e status);
      this.read(name, value, status, UVM_FRONTDOOR);
   endtask

   task read_bd(string name, output uvm_reg_data_t value, output uvm_status_e status);
      this.read(name, value, status, UVM_BACKDOOR);
   endtask // read_bd
 
   task mirror(string name, output uvm_status_e status);
      uvm_reg match_reg;
      jvs_reg_block_wrapper reg_block;
      if (get_reg(name, reg_block, match_reg)) begin
	 `uvm_info(this.get_name(), "mirror begin request!", UVM_HIGH);
	 jvs_reg_resource_manager::get_manager().request_reg_map(get_seqr_adapter(), match_reg.get_default_map().get_root_map());
	 `uvm_info(this.get_name(), "begin mirror!", UVM_HIGH);
	 match_reg.mirror(.status(status), .check(UVM_CHECK), .extension(attr));
	 `uvm_info(this.get_name(), "after mirror!", UVM_HIGH);
	 jvs_reg_resource_manager::get_manager().release_reg_map(get_seqr_adapter(), match_reg.get_default_map().get_root_map());
	 `uvm_info(this.get_name(), "mirror after release!", UVM_HIGH);	 
      end
   endtask // mirror

   task predict(string name, uvm_reg_data_t value);
      uvm_reg match_reg;
      jvs_reg_block_wrapper reg_block;
      if (get_reg(name, reg_block, match_reg)) begin
	 `uvm_info(this.get_name(), "predict begin request!", UVM_HIGH);
	 jvs_reg_resource_manager::get_manager().request_reg_map(get_seqr_adapter(), match_reg.get_default_map().get_root_map());
	 `uvm_info(this.get_name(), "begin predict!", UVM_HIGH);
	 match_reg.predict(value);
	 `uvm_info(this.get_name(), "after predict!", UVM_HIGH);
	 jvs_reg_resource_manager::get_manager().release_reg_map(get_seqr_adapter(), match_reg.get_default_map().get_root_map());
	 `uvm_info(this.get_name(), "predict after release!", UVM_HIGH);	 
      end
   endtask // predict
   
endclass
`endif