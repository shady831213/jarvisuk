`ifndef __JVS_REG_REGION_MAPPER_SV__
 `define __JVS_REG_REGION_MAPPER_SV_

class jvs_reg_region_catcher extends uvm_report_catcher;
   function new(input string name = "jvs_reg_region_catcher");
      super.new(name);
   endfunction // new

   function action_e catch();
      if (get_severity() == UVM_WARNING && get_id() == "RegModel") begin
	 if (uvm_is_match("*Unable to locat*", get_message())) begin
	    return CAUGHT;
	 end
      end
      return THROW;
   endfunction
endclass // jvs_reg_region_catcher

class jvs_reg_region_mapper extends uvm_object;
   `uvm_object_utils_begin(jvs_reg_region_mapper)
   `uvm_object_utils_end

   function new(string name = "jvs_reg_region_mapper");
      jvs_reg_region_catcher catcher;
      super.new(name);
      catcher = new("jvs_reg_region_catcher");
      `ifdef UVM_VERSION_1_2
      uvm_report_cb::add(uvm_get_report_object(), catcher);
      `else
      uvm_report_cb::add(null, catcher);
      `endif
   endfunction // new


   local function void map_rec(uvm_reg_block root_reg_block, jvs_reg_region raw_region);
      uvm_reg_block all_blocks[$];
      root_reg_block.get_blocks(all_blocks, UVM_NO_HIER);
      foreach(all_blocks[i]) begin
	 add_to_region(all_blocks[i], raw_region);
	 map_rec(all_blocks[i], raw_region);
      end
   endfunction // map_rec

   function void map(uvm_reg_block root_reg_block, jvs_reg_region raw_region);
      add_to_region(root_reg_block, raw_region);
      map_rec(root_reg_block, raw_region);
   endfunction // map

   function void unmap(uvm_reg_block root_reg_block, jvs_reg_region raw_region);
      uvm_reg_block all_blocks[$];
      jvs_reg_region parent;
      jvs_reg_block_wrapper reg_wrapper = raw_region.get_reg_block(root_reg_block.get_full_name());
      if (reg_wrapper == null) begin
	 return;
      end
      parent = reg_wrapper.get_parent();
      parent.remove_reg_block(root_reg_block.get_full_name());
      root_reg_block.get_blocks(all_blocks, UVM_HIER);
      foreach(all_blocks[i]) begin
	 parent.remove_reg_block(all_blocks[i].get_full_name());
      end
   endfunction // unmap

   local function void add_to_region(uvm_reg_block reg_block, jvs_reg_region raw_region);
      jvs_reg_block_wrapper reg_wrapper = jvs_reg_block_wrapper::type_id::create(reg_block.get_full_name());
      reg_wrapper.bind_reg_block(reg_block);
      if (!raw_region.add_reg_block(reg_wrapper)) begin
	 raw_region.print();
	 `uvm_fatal(this.get_name(), $psprintf("%0s add failed!", reg_block.get_full_name()));
      end
   endfunction
endclass

`endif