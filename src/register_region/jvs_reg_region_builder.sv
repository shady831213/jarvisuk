`ifndef __JVS_REG_REGION_BUILDER_SV__
 `define __JVS_REG_REGION_BUILDER_SV__
virtual class jvs_reg_region_builder extends uvm_object;
   `uvm_field_utils_begin(jvs_reg_region_builder)
   `uvm_field_utils_end

   function new(string name = "jvs_reg_region_builder");
      super.new(name);
   endfunction // new

   protected function jvs_reg_region create_region(string name,
						   bit [63:0] base_addr,
						   bit [63:0] end_addr,
						   jvs_reg_region parent = null,
						   string attr_class_name = "jvs_reg_region_attr",
						   uvm_sequencer_base seqr = null,
						   uvm_reg_adapter adapter = null
						   );
      bit [63:0] size = end_addr - base_addr + 1;
      bit [63:0] offset = parent == null? base_addr : base_addr - parent.get_base();
      return create_region_by_offset_and_size(name, offset, size, parent, attr_class_name, seqr, adapter);
   endfunction  

   protected function jvs_reg_region create_region_by_offset_and_size(string name,
								      bit [63:0] offset,
								      bit [63:0] size,
								      jvs_reg_region parent = null,
								      string attr_class_name = "jvs_reg_region_attr",
								      uvm_sequencer_base seqr = null,
								      uvm_reg_adapter adapter = null
								      );
      jvs_reg_region region = jvs_reg_region::type_id::create(name);
      region.config_range(offset, size);
      $cast(region.attr, uvm_factory::get().create_object_by_name(attr_class_name));
      if (parent != null) begin
	 if (!parent.add_sub_region(region)) begin
	    parent.print();
	    region.print();
	    `uvm_fatal(this.get_name(), $psprintf("region %0s add failed!", name));
	 end
      end
      region.config_seqr_adapter(jvs_reg_seqr_adapter_pair_factory::get_seqr_adapter_pair(seqr, adapter));
      return region;
   endfunction  

   pure virtual function jvs_reg_region build_region();

 
endclass
`endif