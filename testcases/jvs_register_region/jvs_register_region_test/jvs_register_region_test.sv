`ifndef __JVS_REGISTER_REGION_TEST_SV__
 `define __JVS_REGISTER_REGION_TEST_SV__
 `include "jvs_reg_base_test.sv"
 `include "jvs_test_reg_model.sv"
class jvs_test_region_builder extends jvs_reg_region_builder;
   jvs_reg_test_sequencer sub_block_sequencer, top_block_sequencer;
   jvs_reg_test_adapter sub_block_adapter, top_block_adapter;
   
   `uvm_object_utils(jvs_test_region_builder)

   function new(string name = "jvs_test_region_builder");
      super.new(name);
   endfunction // new

   function jvs_reg_region build_region();
      jvs_reg_region root_region = create_region("top_region", 0, (1 << 27) - 1);
      create_region("top_block", 0, (3 << 24) - 1, root_region, .seqr(top_block_sequencer), .adapter(top_block_adapter));
      create_region("sub_block", 3 << 24, (4 << 24) - 1, root_region, .seqr(sub_block_sequencer), .adapter(sub_block_adapter));      
      return root_region;
   endfunction
endclass // jvs_test_region_builder

class jvs_register_region_test extends jvs_reg_base_test;
   jvs_reg_test_driver top_reg_driver, sub_block_driver, top_block_driver;
   jvs_reg_test_sequencer top_reg_sequencer, sub_block_sequencer, top_block_sequencer;
   jvs_reg_test_adapter top_reg_adapter, sub_block_adapter, top_block_adapter;
   jvs_reg_region root_region;
   `uvm_component_utils(jvs_register_region_test)
     
   function new(string name = "jvs_register_region_test", uvm_component parent);
      super.new(name, parent);
   endfunction // new
     
   virtual function void build_phase(uvm_phase phase);
      jvs_test_region_builder region_builder;
      jvs_test_top_block root_block;
   
      super.build_phase(phase);
      top_reg_driver = jvs_reg_test_driver::type_id::create("top_reg_driver", this);
      sub_block_driver = jvs_reg_test_driver::type_id::create("sub_block_driver", this);
      top_block_driver = jvs_reg_test_driver::type_id::create("top_block_driver", this);

      top_reg_sequencer = jvs_reg_test_sequencer::type_id::create("top_reg_sequencer", this);
      sub_block_sequencer = jvs_reg_test_sequencer::type_id::create("sub_block_sequencer", this);
      top_block_sequencer = jvs_reg_test_sequencer::type_id::create("top_block_sequencer", this);

      top_reg_adapter = jvs_reg_test_adapter::type_id::create("top_reg_adapter", this);
      sub_block_adapter = jvs_reg_test_adapter::type_id::create("sub_block_adapter", this);
      top_block_adapter = jvs_reg_test_adapter::type_id::create("top_block_adapter", this);

      `uvm_info(this.get_name(), "build and map ...", UVM_LOW);
      region_builder = jvs_test_region_builder::type_id::create("region_builder");
      //could config sequencer and adapter when create region
      region_builder.sub_block_sequencer = sub_block_sequencer;
      region_builder.top_block_sequencer = top_block_sequencer;
      region_builder.sub_block_adapter = sub_block_adapter;
      region_builder.top_block_adapter = top_block_adapter;
      root_region = region_builder.build_region();
      root_block = jvs_test_top_block::type_id::create("jvs_test_top_block");
      root_block.build();
      root_block.lock_model();
      region_mapper.map(root_block, root_region);
      root_region.print();

      `uvm_info(this.get_name(), "unmap ...", UVM_LOW);
      region_mapper.unmap(root_block, root_region);
      root_region.print();
   
      `uvm_info(this.get_name(), "remap ...", UVM_LOW);
      region_mapper.map(root_block, root_region);
      root_region.print();

      `uvm_info(this.get_name(), "unmap partial 1...", UVM_LOW);
      region_mapper.unmap(root_block.get_block_by_name("block[1]"), root_region.get_sub_region("top_block"));
      root_region.print();
   
      `uvm_info(this.get_name(), "unmap partial 2...", UVM_LOW);
      region_mapper.unmap(root_block.get_block_by_name("sub_top_block"), root_region);
      root_region.print();
   
      `uvm_info(this.get_name(), "remap ...", UVM_LOW);
      region_mapper.map(root_block.get_block_by_name("sub_top_block"), root_region);
      region_mapper.map(root_block.get_block_by_name("block[1]"), root_region.get_sub_region("top_block"));
      root_region.print();

      //could config sequencer and adapter outside builder
      root_region.config_seqr_adapter(jvs_reg_seqr_adapter_pair_factory::get_seqr_adapter_pair(top_reg_sequencer, top_reg_adapter));
   
   endfunction

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      top_reg_driver.seq_item_port.connect(top_reg_sequencer.seq_item_export);
      sub_block_driver.seq_item_port.connect(sub_block_sequencer.seq_item_export);
      top_block_driver.seq_item_port.connect(top_block_sequencer.seq_item_export);
   endfunction // connect_phase

   virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      super.run_phase(phase);
      fork
	 access_reg("top_region", "top_reg", 32'h5a);
	 access_reg("sub_block", "test_reg", 32'ha5);
	 access_reg("top_block", "test_reg", 32'h5500);	 
      join
      phase.drop_objection(this);
   endtask
   

   task access_reg(string region, string reg_name, bit[31:0] data);
      uvm_status_e status;
      bit [31:0] _data = data;
      
      repeat($urandom_range(1, 3)) begin
	 bit[31:0] rdata;
	 `uvm_info(this.get_name(), $psprintf("write @ %0s in region %0s", reg_name, region), UVM_LOW);
	 root_region.get_region(region).write_fd(reg_name, _data, status);
	 `uvm_info(this.get_name(), $psprintf("write complete @ %0s in region %0s", reg_name, region), UVM_LOW);
	 `uvm_info(this.get_name(), $psprintf("read @ %0s in region %0s", reg_name, region), UVM_LOW);
	 root_region.get_region(region).read_fd(reg_name, rdata, status);
	 `uvm_info(this.get_name(), $psprintf("read complete @ %0s in region %0s", reg_name, region), UVM_LOW);
	 if (rdata != _data) begin
	    `uvm_error(this.get_name(), $psprintf("access error @ %0s in region %0s, expect data = 0x%0x, but get 0x%0x!", reg_name, region, _data, rdata));
	 end
	 _data = ~_data;
      end
   endtask
endclass
`endif